import 'package:cloud_firestore/cloud_firestore.dart';

class Couple {
  final String id;
  final List<String> memberUids;
  final DateTime createdAt;

  const Couple({
    required this.id,
    required this.memberUids,
    required this.createdAt,
  });

  factory Couple.fromMap(String id, Map<String, dynamic> map) {
    return Couple(
      id: id,
      memberUids: map['memberUids'] != null
          ? List<String>.from(map['memberUids'] as List)
          : const [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberUids': memberUids,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  bool get isPaired => memberUids.length == 2;
}
