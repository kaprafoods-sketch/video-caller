// TODO: localize to Hindi later

/// Centralized UI strings for the app.
abstract final class AppStrings {
  // App identity
  static const String appName = 'Duet';
  static const String tagline = 'Stay close, wherever you are.';

  // Authentication
  static const String signInWithGoogle = 'Sign in with Google';
  static const String signInError = 'Sign-in failed. Please try again.';
  static const String signOut = 'Sign out';

  // Invites & pairing
  static const String createInvite = 'Create invite';
  static const String yourInviteCode = 'Your invite code';
  static const String inviteCodeHint =
      'Share this code with your partner. It expires in 24 hours.';
  static const String enterCode = 'Enter code';
  static const String enterCodeHint = 'Enter the code your partner shared';
  static const String redeemInvite = 'Redeem invite';
  static const String pair = 'Pair';
  static const String codeExpired = 'This code has expired.';
  static const String invalidCode = 'That code is invalid.';
  static const String alreadyPaired = 'You are already paired.';
  static const String notPaired = 'You are not paired yet.';
  static const String unpair = 'Unpair';
  static const String unpairConfirm =
      'Are you sure you want to unpair? This cannot be undone.';
  static const String cancel = 'Cancel';

  // Calling
  static const String startCall = 'Start call';
  static const String callError = 'Something went wrong with the call.';
  static const String waitingForPartner = 'Waiting for your partner…';
  static const String joinCall = 'Join';
  static const String endCall = 'End call';
  static const String incomingCallTitle = 'Your partner started a call';
  static const String incomingCallBody = 'Tap Join to hop in.';
  static const String callStarting = 'Starting your call…';
  static const String callInProgress = 'Call in progress';
  static const String requestingCalendarAccess =
      'Connecting to your Google Calendar…';
  static const String calendarAccessDenied =
      'Calendar access is needed to create a Meet link. Please allow it and try again.';
  static const String couldNotOpenCall = 'Could not open the call link.';
  static const String noActiveCall = 'No one has started a call yet.';

  // Mood
  static const String partnerMoodPrefix = 'is feeling';
  static const String moodHappy = 'Happy';
  static const String moodLoved = 'Loved';
  static const String moodCalm = 'Calm';
  static const String moodPlayful = 'Playful';
  static const String moodTired = 'Tired';
  static const String moodStressed = 'Stressed';
  static const String moodSad = 'Sad';
  static const String moodAnxious = 'Anxious';
  static const String checkInTitle = 'How are you feeling?';
  static const String checkInSubtitle =
      'Shared openly with your partner — no judgment here.';
  static const String checkInNoteHint = 'Add a note (optional)';
  static const String saveMood = 'Share how I feel';
  static const String moodSaved = 'Mood shared 💛';
  static const String moodSaveError =
      'Could not save your mood. Please try again.';
  static const String partnerNoMoodSuffix = "hasn't checked in yet";
  static const String partnerWaitingToJoin =
      'Waiting for your partner to join Duet.';
  static const String yourMoodLabel = 'Your mood';

  // Movie night
  static const String movieNightTitle = 'Movie night';
  static const String movieNightSubtitle =
      'Get suggestions you both might love, then vote.';
  static const String suggestMovies = 'Suggest movies';
  static const String suggestingMovies = 'Finding movies for you two…';
  static const String movieSuggestError =
      'Could not fetch movie suggestions. Please try again.';
  static const String noSuggestionsFound =
      'No movies matched your tastes — try adding more genres.';
  static const String voteHint = 'Tap the movies you would watch tonight.';
  static const String submitVotes = 'Lock in my picks';
  static const String votesSaved = 'Picks saved 🍿';
  static const String voteSaveError =
      'Could not save your picks. Please try again.';
  static const String waitingForPartnerVotes =
      'Waiting for your partner to pick…';
  static const String itsAMatch = "It's a match!";
  static const String noMatchesYet =
      'No overlap this time — vote again or pick together.';
  static const String genrePreferencesTitle = 'Your favorite genres';
  static const String genrePreferencesHint =
      'Pick a few genres so suggestions fit you both.';
  static const String saveGenres = 'Save genres';
  static const String genrePreferencesSaved = 'Genres saved';
  static const String genrePreferencesSaveError =
      'Could not save your genres. Please try again.';

  // Genres
  static const String genreAction = 'Action';
  static const String genreAdventure = 'Adventure';
  static const String genreAnimation = 'Animation';
  static const String genreComedy = 'Comedy';
  static const String genreCrime = 'Crime';
  static const String genreDocumentary = 'Documentary';
  static const String genreDrama = 'Drama';
  static const String genreFamily = 'Family';
  static const String genreFantasy = 'Fantasy';
  static const String genreHistory = 'History';
  static const String genreHorror = 'Horror';
  static const String genreMusic = 'Music';
  static const String genreMystery = 'Mystery';
  static const String genreRomance = 'Romance';
  static const String genreScienceFiction = 'Sci-Fi';
  static const String genreThriller = 'Thriller';
  static const String genreWar = 'War';
  static const String genreWestern = 'Western';

  // Prompts & confessions
  static const String promptsTitle = 'Prompts & confessions';
  static const String promptsLobbySubtitle = 'Ask, confess, and unlock together.';
  static const String promptTypeQuestion = 'Question';
  static const String promptTypeConfession = 'Confession';
  static const String pickQuestion = 'Pick a question';
  static const String yourAnswerHint = 'Your answer…';
  static const String yourConfessionHint =
      "Something you've been meaning to say…";
  static const String sealAnswer = 'Seal my answer';
  static const String sealConfession = 'Seal my confession';
  static const String promptSealed =
      'Sealed 🤫 It unlocks when your partner shares too.';
  static const String promptSealError =
      'Could not seal that. Please try again.';
  static const String promptsEmpty = 'Nothing here yet — break the ice above.';
  static const String promptSealedWaiting =
      'Sealed — waiting for your partner to share.';
  static const String promptRevealedTogether = 'Revealed together';
  static const String promptFromYou = 'You';
  static const String promptFromPartner = 'Your partner';
  static const String pickAQuestionFirst = 'Pick a question first.';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';

  // Disclaimers
  static const String promptsDisclaimer =
      'Duet is for connection, not a substitute for professional support.';
}
