import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class CoupleService {
  CoupleService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;

  /// Streams the partner's [AppUser] for [coupleId] from the perspective of
  /// [myUid]. Emits null while the partner is unknown (couple missing, still
  /// pending, or the partner's user doc absent).
  Stream<AppUser?> watchPartner({
    required String coupleId,
    required String myUid,
  }) {
    return _db.collection('couples').doc(coupleId).snapshots().asyncExpand((coupleSnap) {
      if (!coupleSnap.exists) return Stream<AppUser?>.value(null);
      final members = List<String>.from(
        (coupleSnap.data()?['memberUids'] as List<dynamic>?) ?? const [],
      );
      final partnerUid = members.firstWhere((u) => u != myUid, orElse: () => '');
      if (partnerUid.isEmpty) return Stream<AppUser?>.value(null);
      return _db.collection('users').doc(partnerUid).snapshots().map(
            (userSnap) => userSnap.exists
                ? AppUser.fromMap(partnerUid, userSnap.data()!)
                : null,
          );
    });
  }
}
