export interface TmdbMovie {
  tmdbId: number;
  title: string;
  overview: string;
  posterPath: string | null;
  releaseYear: number | null;
  voteAverage: number;
}

/**
 * TMDB genre ids keyed by the genre names stored in users/{uid}.genrePreferences.
 * The API key never leaves the server; clients only ever see the resulting
 * suggestion docs in Firestore.
 */
export const TMDB_GENRE_IDS: Record<string, number> = {
  action: 28,
  adventure: 12,
  animation: 16,
  comedy: 35,
  crime: 80,
  documentary: 99,
  drama: 18,
  family: 10751,
  fantasy: 14,
  history: 36,
  horror: 27,
  music: 10402,
  mystery: 9648,
  romance: 10749,
  scienceFiction: 878,
  thriller: 53,
  war: 10752,
  western: 37,
};

export async function fetchTmdbSuggestions(
  apiKey: string,
  genreIds: number[]
): Promise<TmdbMovie[]> {
  const params = new URLSearchParams({
    api_key: apiKey,
    sort_by: "popularity.desc",
    include_adult: "false",
    "vote_count.gte": "100",
  });
  if (genreIds.length > 0) {
    params.set("with_genres", genreIds.join("|"));
  }

  const res = await fetch(
    `https://api.themoviedb.org/3/discover/movie?${params.toString()}`
  );
  if (!res.ok) {
    throw new Error(`tmdb-api-error: ${res.status}`);
  }

  const data = (await res.json()) as {
    results?: Array<{
      id: number;
      title?: string;
      overview?: string;
      poster_path?: string | null;
      release_date?: string;
      vote_average?: number;
    }>;
  };

  return (data.results ?? []).map((m) => ({
    tmdbId: m.id,
    title: m.title ?? "",
    overview: m.overview ?? "",
    posterPath: m.poster_path ?? null,
    releaseYear: m.release_date ? Number(m.release_date.slice(0, 4)) || null : null,
    voteAverage: m.vote_average ?? 0,
  }));
}
