import '../models/movie_genre.dart';
import 'strings.dart';

/// Localized display label for a [MovieGenre]. Kept out of the model so the
/// enum stays presentation-free; update here (and AppStrings) when localizing.
String genreLabel(MovieGenre genre) {
  switch (genre) {
    case MovieGenre.action:
      return AppStrings.genreAction;
    case MovieGenre.adventure:
      return AppStrings.genreAdventure;
    case MovieGenre.animation:
      return AppStrings.genreAnimation;
    case MovieGenre.comedy:
      return AppStrings.genreComedy;
    case MovieGenre.crime:
      return AppStrings.genreCrime;
    case MovieGenre.documentary:
      return AppStrings.genreDocumentary;
    case MovieGenre.drama:
      return AppStrings.genreDrama;
    case MovieGenre.family:
      return AppStrings.genreFamily;
    case MovieGenre.fantasy:
      return AppStrings.genreFantasy;
    case MovieGenre.history:
      return AppStrings.genreHistory;
    case MovieGenre.horror:
      return AppStrings.genreHorror;
    case MovieGenre.music:
      return AppStrings.genreMusic;
    case MovieGenre.mystery:
      return AppStrings.genreMystery;
    case MovieGenre.romance:
      return AppStrings.genreRomance;
    case MovieGenre.scienceFiction:
      return AppStrings.genreScienceFiction;
    case MovieGenre.thriller:
      return AppStrings.genreThriller;
    case MovieGenre.war:
      return AppStrings.genreWar;
    case MovieGenre.western:
      return AppStrings.genreWestern;
  }
}
