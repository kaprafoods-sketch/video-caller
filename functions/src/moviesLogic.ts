import type { Firestore } from "firebase-admin/firestore";
import { FieldValue } from "firebase-admin/firestore";
import { TMDB_GENRE_IDS, type TmdbMovie } from "./tmdb";

export type MovieErrorCode =
  | "not-paired"
  | "not-a-member"
  | "couple-not-full"
  | "no-suggestions";

export class MovieError extends Error {
  constructor(public code: MovieErrorCode, message?: string) {
    super(message ?? code);
  }
}

export const MAX_SUGGESTIONS = 10;

/**
 * Merges two partners' genre preference names into a TMDB genre id list,
 * shared genres first so mutual tastes dominate the discover query.
 * Unknown names are ignored.
 */
export function mergeGenrePreferences(a: string[], b: string[]): number[] {
  const shared = a.filter((g) => b.includes(g));
  const rest = [...a, ...b].filter((g) => !shared.includes(g));
  const ids: number[] = [];
  for (const name of [...shared, ...rest]) {
    const id = TMDB_GENRE_IDS[name];
    if (id !== undefined && !ids.includes(id)) {
      ids.push(id);
    }
  }
  return ids;
}

export async function suggestMoviesFor(
  db: Firestore,
  uid: string,
  coupleId: string,
  fetchMovies: (genreIds: number[]) => Promise<TmdbMovie[]>
): Promise<{ movieNightId: string }> {
  const coupleRef = db.collection("couples").doc(coupleId);
  const coupleSnap = await coupleRef.get();
  const coupleData = coupleSnap.data();
  if (!coupleData) {
    throw new MovieError("not-paired");
  }

  const memberUids: string[] = coupleData.memberUids ?? [];
  if (memberUids.length !== 2) {
    throw new MovieError("couple-not-full");
  }
  if (!memberUids.includes(uid)) {
    throw new MovieError("not-a-member");
  }

  const userSnaps = await Promise.all(
    memberUids.map((m) => db.collection("users").doc(m).get())
  );
  const [prefsA, prefsB] = userSnaps.map(
    (s) => (s.data()?.genrePreferences ?? []) as string[]
  );

  const movies = await fetchMovies(mergeGenrePreferences(prefsA, prefsB));
  const suggestions = movies.slice(0, MAX_SUGGESTIONS);
  if (suggestions.length === 0) {
    throw new MovieError("no-suggestions");
  }

  const nightRef = coupleRef.collection("movieNights").doc();
  await nightRef.set({
    startedBy: uid,
    createdAt: FieldValue.serverTimestamp(),
    suggestions,
    votes: {},
  });

  return { movieNightId: nightRef.id };
}
