process.env.FIRESTORE_EMULATOR_HOST ??= "127.0.0.1:8080";

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { describe, it, expect } from "vitest";
import {
  MovieError,
  mergeGenrePreferences,
  suggestMoviesFor,
  MAX_SUGGESTIONS,
} from "../src/moviesLogic";
import type { TmdbMovie } from "../src/tmdb";

if (getApps().length === 0) {
  initializeApp({ projectId: "duet-dev" });
}
const db = getFirestore();

async function seedCouple(coupleId: string, memberUids: string[]): Promise<void> {
  await db.collection("couples").doc(coupleId).set({
    memberUids,
    createdAt: FieldValue.serverTimestamp(),
  });
}

async function seedUser(uid: string, genrePreferences: string[]): Promise<void> {
  await db.collection("users").doc(uid).set({
    displayName: uid,
    genrePreferences,
    coupleId: null,
  });
}

function fakeMovie(id: number): TmdbMovie {
  return {
    tmdbId: id,
    title: `Movie ${id}`,
    overview: `Overview ${id}`,
    posterPath: `/poster${id}.jpg`,
    releaseYear: 2020,
    voteAverage: 7.5,
  };
}

const fakeFetch =
  (movies: TmdbMovie[]) =>
  async (_genreIds: number[]): Promise<TmdbMovie[]> =>
    movies;

async function expectMovieError(promise: Promise<unknown>, code: string): Promise<void> {
  await expect(promise).rejects.toThrow();
  try {
    await promise;
    throw new Error("expected promise to reject");
  } catch (err) {
    expect(err).toBeInstanceOf(MovieError);
    expect((err as MovieError).code).toBe(code);
  }
}

describe("mergeGenrePreferences", () => {
  it("puts shared genres first, then the rest, deduped, as TMDB ids", () => {
    const ids = mergeGenrePreferences(
      ["comedy", "action", "romance"],
      ["romance", "horror", "comedy"]
    );
    // shared: comedy(35), romance(10749); rest: action(28), horror(27)
    expect(ids).toEqual([35, 10749, 28, 27]);
  });

  it("ignores unknown genre names", () => {
    expect(mergeGenrePreferences(["comedy", "bollywood"], ["kdrama"])).toEqual([35]);
  });

  it("returns empty for users with no preferences", () => {
    expect(mergeGenrePreferences([], [])).toEqual([]);
  });
});

describe("suggestMoviesFor", () => {
  it(
    "happy path writes a movieNights doc with suggestions and empty votes",
    async () => {
      await seedCouple("mc1", ["A", "B"]);
      await seedUser("A", ["comedy"]);
      await seedUser("B", ["romance"]);

      const movies = [1, 2, 3].map(fakeMovie);
      const res = await suggestMoviesFor(db, "A", "mc1", fakeFetch(movies));
      expect(res.movieNightId.length).toBeGreaterThan(0);

      const snap = await db
        .collection("couples")
        .doc("mc1")
        .collection("movieNights")
        .doc(res.movieNightId)
        .get();
      const data = snap.data();
      expect(data?.startedBy).toBe("A");
      expect(data?.createdAt).toBeDefined();
      expect(data?.votes).toEqual({});
      expect(data?.suggestions).toHaveLength(3);
      expect(data?.suggestions[0]).toEqual(fakeMovie(1));
    },
    10000
  );

  it(
    "passes both partners' merged genre ids to the fetcher",
    async () => {
      await seedCouple("mc2", ["A2", "B2"]);
      await seedUser("A2", ["comedy", "action"]);
      await seedUser("B2", ["comedy", "horror"]);

      let received: number[] = [];
      await suggestMoviesFor(db, "B2", "mc2", async (genreIds) => {
        received = genreIds;
        return [fakeMovie(1)];
      });
      expect(received).toEqual([35, 28, 27]);
    },
    10000
  );

  it(
    "caps suggestions at MAX_SUGGESTIONS",
    async () => {
      await seedCouple("mc3", ["A3", "B3"]);
      await seedUser("A3", []);
      await seedUser("B3", []);

      const many = Array.from({ length: 20 }, (_, i) => fakeMovie(i + 1));
      const res = await suggestMoviesFor(db, "A3", "mc3", fakeFetch(many));
      const snap = await db
        .collection("couples")
        .doc("mc3")
        .collection("movieNights")
        .doc(res.movieNightId)
        .get();
      expect(snap.data()?.suggestions).toHaveLength(MAX_SUGGESTIONS);
    },
    10000
  );

  it(
    "fails not-paired for a missing couple",
    async () => {
      await expectMovieError(
        suggestMoviesFor(db, "A", "nope", fakeFetch([fakeMovie(1)])),
        "not-paired"
      );
    },
    10000
  );

  it(
    "fails couple-not-full for a pending couple",
    async () => {
      await seedCouple("mc4", ["A4"]);
      await expectMovieError(
        suggestMoviesFor(db, "A4", "mc4", fakeFetch([fakeMovie(1)])),
        "couple-not-full"
      );
    },
    10000
  );

  it(
    "fails not-a-member for an outsider",
    async () => {
      await seedCouple("mc5", ["A5", "B5"]);
      await expectMovieError(
        suggestMoviesFor(db, "C5", "mc5", fakeFetch([fakeMovie(1)])),
        "not-a-member"
      );
    },
    10000
  );

  it(
    "fails no-suggestions when the fetcher returns nothing",
    async () => {
      await seedCouple("mc6", ["A6", "B6"]);
      await seedUser("A6", ["western"]);
      await seedUser("B6", ["war"]);
      await expectMovieError(
        suggestMoviesFor(db, "A6", "mc6", fakeFetch([])),
        "no-suggestions"
      );
    },
    10000
  );
});
