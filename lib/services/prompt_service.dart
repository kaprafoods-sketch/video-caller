import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../l10n/strings.dart';
import '../models/prompt.dart';
import '../models/prompt_type.dart';

class PromptException implements Exception {
  final String message;
  PromptException(this.message);

  @override
  String toString() => message;
}

/// Prompts & confessions. Clients only ever *seal* prompts (write with
/// `unlockedAt: null`); the reveal is done server-side by the onPromptCreated
/// trigger, and the Firestore rules forbid clients from touching `unlockedAt`.
class PromptService {
  final FirebaseFirestore _db;

  PromptService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _prompts(String coupleId) =>
      _db.collection('couples').doc(coupleId).collection('prompts');

  Future<void> _seal({
    required String coupleId,
    required String uid,
    required PromptType type,
    required String pairKey,
    required String content,
  }) async {
    try {
      await _prompts(coupleId).add({
        'authorUid': uid,
        'type': type.name,
        'pairKey': pairKey,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'unlockedAt': null,
      });
    } on FirebaseException {
      throw PromptException(AppStrings.promptSealError);
    }
  }

  /// Seals an answer to a shared question. Reveals once the partner answers
  /// the same question.
  Future<void> answerQuestion({
    required String coupleId,
    required String uid,
    required String questionId,
    required String content,
  }) {
    return _seal(
      coupleId: coupleId,
      uid: uid,
      type: PromptType.question,
      pairKey: questionId,
      content: content,
    );
  }

  /// Seals a free-form confession. Reveals once the partner also has a sealed
  /// confession (oldest-first).
  Future<void> confess({
    required String coupleId,
    required String uid,
    required String content,
  }) {
    return _seal(
      coupleId: coupleId,
      uid: uid,
      type: PromptType.confession,
      pairKey: kConfessionPairKey,
      content: content,
    );
  }

  /// Streams every prompt this user is allowed to see: their own (sealed or
  /// unlocked) plus all unlocked prompts from either partner. Two queries are
  /// merged because the rules deny reading the partner's *sealed* prompts, so
  /// a single "all prompts" query would be rejected.
  Stream<List<Prompt>> watchVisiblePrompts({
    required String coupleId,
    required String myUid,
  }) {
    final controller = StreamController<List<Prompt>>();
    List<Prompt>? mine;
    List<Prompt>? unlocked;

    void emit() {
      if (mine == null && unlocked == null) return;
      final byId = <String, Prompt>{};
      for (final p in [...?mine, ...?unlocked]) {
        byId[p.id] = p;
      }
      final list = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }

    List<Prompt> parse(QuerySnapshot<Map<String, dynamic>> qs) =>
        qs.docs.map((d) => Prompt.fromMap(d.id, d.data())).toList();

    final subMine = _prompts(coupleId)
        .where('authorUid', isEqualTo: myUid)
        .snapshots()
        .listen((qs) {
      mine = parse(qs);
      emit();
    }, onError: controller.addError);

    final subUnlocked = _prompts(coupleId)
        .where('unlockedAt', isNull: false)
        .snapshots()
        .listen((qs) {
      unlocked = parse(qs);
      emit();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await subMine.cancel();
      await subUnlocked.cancel();
    };

    return controller.stream;
  }
}
