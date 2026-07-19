import 'package:cloud_firestore/cloud_firestore.dart';

import 'prompt_type.dart';

/// A sealed note one partner wrote — a question answer or a confession. It is
/// visible only to its author until [unlockedAt] is set (by the server-side
/// unlock trigger), at which point both partners' matching prompts reveal
/// together. See functions/src/promptsLogic.ts for the mechanic.
class Prompt {
  final String id;
  final String authorUid;
  final PromptType type;

  /// The question's id, or [kConfessionPairKey] for confessions.
  final String pairKey;
  final String content;
  final DateTime createdAt;
  final DateTime? unlockedAt;

  const Prompt({
    required this.id,
    required this.authorUid,
    required this.type,
    required this.pairKey,
    required this.content,
    required this.createdAt,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  factory Prompt.fromMap(String id, Map<String, dynamic> map) {
    return Prompt(
      id: id,
      authorUid: map['authorUid'] as String? ?? '',
      type: PromptType.fromName(map['type'] as String?),
      pairKey: map['pairKey'] as String? ?? kConfessionPairKey,
      content: map['content'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      unlockedAt: (map['unlockedAt'] as Timestamp?)?.toDate(),
    );
  }
}
