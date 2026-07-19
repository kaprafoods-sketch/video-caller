import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

/// Wraps Firebase Auth and Google Sign-In for the app's authentication flow.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  /// Emits the current [User] whenever the auth state changes.
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  /// The currently signed-in user, if any.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Signs the user in with Google and ensures their Firestore user
  /// document exists.
  ///
  // TODO: web sign-in uses a different flow
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _firebaseAuth.signInWithCredential(credential);
    final user = cred.user;
    if (user != null) {
      await _ensureUserDocument(user);
    }

    return cred;
  }

  Future<void> _ensureUserDocument(User user) async {
    final docRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      final appUser = AppUser(
        uid: user.uid,
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
        genrePreferences: const [],
        coupleId: null,
      );
      await docRef.set(appUser.toMap());
    }
  }

  /// Signs the user out of both Google Sign-In and Firebase Auth.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// Requests the given OAuth [scopes] for the signed-in Google account and
  /// returns a fresh access token that carries them. Throws [CalendarAuthException]
  /// if the account is unavailable or the user denies the scopes.
  Future<String> accessTokenForScopes(List<String> scopes) async {
    var account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
    if (account == null) {
      // Fall back to interactive sign-in if there is no cached account.
      account = await _googleSignIn.signIn();
    }
    if (account == null) {
      throw CalendarAuthException('No Google account is available.');
    }
    final granted = await _googleSignIn.requestScopes(scopes);
    if (!granted) {
      throw CalendarAuthException('The requested Google scopes were denied.');
    }
    final auth = await account.authentication;
    final token = auth.accessToken;
    if (token == null) {
      throw CalendarAuthException('Could not obtain a Google access token.');
    }
    return token;
  }
}

/// Raised when the app cannot obtain a Google OAuth access token with the
/// scopes needed (e.g. Calendar access for Meet link creation).
class CalendarAuthException implements Exception {
  CalendarAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}
