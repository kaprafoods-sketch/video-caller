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

  // Mood
  static const String partnerMoodPrefix = 'is feeling';

  // Errors
  static const String genericError = 'Something went wrong. Please try again.';

  // Disclaimers
  static const String promptsDisclaimer =
      'Duet is for connection, not a substitute for professional support.';
}
