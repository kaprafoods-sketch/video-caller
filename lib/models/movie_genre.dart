/// Movie genres a user can pick as preferences. The [name] of each value is
/// what gets stored in users/{uid}.genrePreferences; the server maps names to
/// TMDB genre ids, so no TMDB details leak into the app.
enum MovieGenre {
  action,
  adventure,
  animation,
  comedy,
  crime,
  documentary,
  drama,
  family,
  fantasy,
  history,
  horror,
  music,
  mystery,
  romance,
  scienceFiction,
  thriller,
  war,
  western;

  static MovieGenre? fromName(String? name) {
    for (final g in MovieGenre.values) {
      if (g.name == name) return g;
    }
    return null;
  }
}
