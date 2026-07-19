/// One movie suggested by the `suggestMovies` Cloud Function. Posters load via
/// Image.network from TMDB's public image CDN; only the server holds the key.
class MovieSuggestion {
  final int tmdbId;
  final String title;
  final String overview;
  final String? posterPath;
  final int? releaseYear;
  final double voteAverage;

  const MovieSuggestion({
    required this.tmdbId,
    required this.title,
    required this.overview,
    this.posterPath,
    this.releaseYear,
    this.voteAverage = 0,
  });

  /// Full poster image URL, or null when TMDB has no poster for this movie.
  String? get posterUrl =>
      posterPath == null ? null : 'https://image.tmdb.org/t/p/w342$posterPath';

  factory MovieSuggestion.fromMap(Map<String, dynamic> map) {
    return MovieSuggestion(
      tmdbId: (map['tmdbId'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? '',
      overview: map['overview'] as String? ?? '',
      posterPath: map['posterPath'] as String?,
      releaseYear: (map['releaseYear'] as num?)?.toInt(),
      voteAverage: (map['voteAverage'] as num?)?.toDouble() ?? 0,
    );
  }
}
