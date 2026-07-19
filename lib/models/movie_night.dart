import 'package:cloud_firestore/cloud_firestore.dart';

import 'movie_suggestion.dart';

/// A movie-night session: server-written suggestions plus each partner's
/// votes (a list of tmdbIds keyed by uid, written by clients via Firestore).
class MovieNight {
  final String id;
  final String startedBy;
  final DateTime createdAt;
  final List<MovieSuggestion> suggestions;
  final Map<String, List<int>> votes;

  const MovieNight({
    required this.id,
    required this.startedBy,
    required this.createdAt,
    required this.suggestions,
    required this.votes,
  });

  factory MovieNight.fromMap(String id, Map<String, dynamic> map) {
    return MovieNight(
      id: id,
      startedBy: map['startedBy'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      suggestions: (map['suggestions'] as List? ?? const [])
          .map((s) => MovieSuggestion.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      votes: (map['votes'] as Map? ?? const {}).map(
        (uid, ids) => MapEntry(
          uid as String,
          (ids as List? ?? const []).map((i) => (i as num).toInt()).toList(),
        ),
      ),
    );
  }

  List<int> votesFor(String uid) => votes[uid] ?? const [];

  bool hasVoted(String uid) => votes.containsKey(uid);

  bool get bothVoted => votes.length >= 2;

  /// Movies both partners voted for, in suggestion order. Only meaningful once
  /// [bothVoted] is true.
  List<MovieSuggestion> get matches {
    if (!bothVoted) return const [];
    final voteLists = votes.values.toList();
    return suggestions
        .where((s) => voteLists.every((ids) => ids.contains(s.tmdbId)))
        .toList();
  }
}
