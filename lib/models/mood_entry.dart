import 'package:cloud_firestore/cloud_firestore.dart';

import 'mood.dart';

class MoodEntry {
  final String uid;
  final Mood mood;
  final String note;
  final DateTime createdAt;

  const MoodEntry({
    required this.uid,
    required this.mood,
    required this.note,
    required this.createdAt,
  });

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      uid: map['uid'] as String? ?? '',
      mood: Mood.fromName(map['mood'] as String?) ?? Mood.calm,
      note: map['note'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
