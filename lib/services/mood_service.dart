import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/mood.dart';
import '../models/mood_entry.dart';

class MoodService {
  MoodService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _moods(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('moods');

  /// Records a new mood check-in for [uid] in the couple. Moods are shared
  /// openly with the partner — there is no private/hidden mood.
  Future<void> checkIn({
    required String coupleId,
    required String uid,
    required Mood mood,
    String note = '',
  }) {
    return _moods(coupleId).add({
      'uid': uid,
      'mood': mood.name,
      'note': note,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Streams the most recent mood check-in for [uid], or null if none yet.
  Stream<MoodEntry?> watchLatestMood({
    required String coupleId,
    required String uid,
  }) {
    return _moods(coupleId)
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((qs) =>
            qs.docs.isEmpty ? null : MoodEntry.fromMap(qs.docs.first.data()));
  }
}
