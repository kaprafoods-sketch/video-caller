import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../l10n/strings.dart';
import '../models/movie_genre.dart';
import '../models/movie_night.dart';

class MovieNightException implements Exception {
  final String code;
  final String message;

  MovieNightException(this.code, this.message);

  @override
  String toString() => message;
}

/// Movie night: suggestions come from the `suggestMovies` Cloud Function
/// (which holds the TMDB key server-side); votes and genre preferences are
/// plain Firestore writes from the client.
class MovieService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  MovieService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _nights(String coupleId) =>
      _firestore.collection('couples').doc(coupleId).collection('movieNights');

  /// Asks the server for a fresh round of suggestions and returns the new
  /// movie night's document id.
  Future<String> suggestMovies(String coupleId) async {
    try {
      final result = await _functions
          .httpsCallable('suggestMovies')
          .call({'coupleId': coupleId});
      final data = result.data as Map;
      return data['movieNightId'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  /// Streams the most recent movie night, or null if none yet.
  Stream<MovieNight?> watchLatestMovieNight(String coupleId) {
    return _nights(coupleId)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((qs) => qs.docs.isEmpty
            ? null
            : MovieNight.fromMap(qs.docs.first.id, qs.docs.first.data()));
  }

  /// Records [uid]'s picks for a movie night. Voting again replaces the
  /// previous picks.
  Future<void> vote({
    required String coupleId,
    required String movieNightId,
    required String uid,
    required List<int> tmdbIds,
  }) async {
    try {
      await _nights(coupleId).doc(movieNightId).update({'votes.$uid': tmdbIds});
    } on FirebaseException {
      throw MovieNightException('vote-failed', AppStrings.voteSaveError);
    }
  }

  /// Saves [uid]'s genre preferences, edited inline where they're used.
  Future<void> updateGenrePreferences({
    required String uid,
    required List<MovieGenre> genres,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'genrePreferences': genres.map((g) => g.name).toList(),
      });
    } on FirebaseException {
      throw MovieNightException(
          'genres-failed', AppStrings.genrePreferencesSaveError);
    }
  }

  MovieNightException _mapError(FirebaseFunctionsException e) {
    final code = (e.details is Map ? (e.details as Map)['code'] : null) as String? ??
        e.code;
    switch (code) {
      case 'no-suggestions':
        return MovieNightException(code, AppStrings.noSuggestionsFound);
      case 'not-paired':
      case 'couple-not-full':
        return MovieNightException(code, AppStrings.notPaired);
      case 'tmdb-error':
        return MovieNightException(code, AppStrings.movieSuggestError);
      default:
        return MovieNightException(code, AppStrings.genericError);
    }
  }
}
