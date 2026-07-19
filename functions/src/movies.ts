import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { getFirestore } from "firebase-admin/firestore";
import { MovieError, suggestMoviesFor } from "./moviesLogic";
import { fetchTmdbSuggestions } from "./tmdb";

const tmdbApiKey = defineSecret("TMDB_API_KEY");

function mapMovieError(e: unknown): never {
  if (e instanceof MovieError) {
    throw new HttpsError("failed-precondition", e.message, { code: e.code });
  }
  if (e instanceof HttpsError) {
    throw e;
  }
  if (e instanceof Error && e.message.startsWith("tmdb-api-error")) {
    throw new HttpsError("internal", e.message, { code: "tmdb-error" });
  }
  throw e;
}

export const suggestMovies = onCall({ secrets: [tmdbApiKey] }, async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Must be signed in.");
  }
  const coupleId = request.data?.coupleId as string;
  if (!coupleId) {
    throw new HttpsError("invalid-argument", "coupleId is required.");
  }
  try {
    return await suggestMoviesFor(getFirestore(), request.auth.uid, coupleId, (genreIds) =>
      fetchTmdbSuggestions(tmdbApiKey.value(), genreIds)
    );
  } catch (e) {
    mapMovieError(e);
  }
});
