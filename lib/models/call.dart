import 'package:cloud_firestore/cloud_firestore.dart';

class Call {
  final String id;
  final String meetUrl;
  final String startedBy;
  final DateTime startedAt;
  final DateTime? endedAt;

  const Call({
    required this.id,
    required this.meetUrl,
    required this.startedBy,
    required this.startedAt,
    this.endedAt,
  });

  factory Call.fromMap(String id, Map<String, dynamic> map) {
    return Call(
      id: id,
      meetUrl: map['meetUrl'] as String? ?? '',
      startedBy: map['startedBy'] as String? ?? '',
      startedAt: (map['startedAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      endedAt: (map['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  bool get isActive => endedAt == null;

  bool startedByMe(String uid) => startedBy == uid;
}
