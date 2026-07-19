import '../models/mood.dart';
import 'strings.dart';

/// Localized display label for a [Mood]. Kept out of the model so the enum
/// stays presentation-free; update here (and AppStrings) when localizing.
String moodLabel(Mood mood) {
  switch (mood) {
    case Mood.happy:
      return AppStrings.moodHappy;
    case Mood.loved:
      return AppStrings.moodLoved;
    case Mood.calm:
      return AppStrings.moodCalm;
    case Mood.playful:
      return AppStrings.moodPlayful;
    case Mood.tired:
      return AppStrings.moodTired;
    case Mood.stressed:
      return AppStrings.moodStressed;
    case Mood.sad:
      return AppStrings.moodSad;
    case Mood.anxious:
      return AppStrings.moodAnxious;
  }
}
