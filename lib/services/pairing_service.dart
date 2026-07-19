import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../l10n/strings.dart';
import '../models/app_user.dart';

class PairingException implements Exception {
  final String code;
  final String message;

  PairingException(this.code, this.message);

  @override
  String toString() => message;
}

class PairingService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  PairingService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
      : _functions = functions ?? FirebaseFunctions.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String> createInvite() async {
    try {
      final result = await _functions.httpsCallable('createInvite').call();
      final data = result.data as Map;
      return data['inviteCode'] as String;
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> redeemInvite(String code) async {
    try {
      await _functions.httpsCallable('redeemInvite').call({'code': code});
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> unpair() async {
    try {
      await _functions.httpsCallable('unpair').call();
    } on FirebaseFunctionsException catch (e) {
      throw _mapError(e);
    }
  }

  Stream<AppUser?> watchCurrentUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map(
          (snap) => snap.exists ? AppUser.fromMap(uid, snap.data()!) : null,
        );
  }

  PairingException _mapError(FirebaseFunctionsException e) {
    String code = e.code;
    String message = e.message ?? AppStrings.genericError;

    final details = e.details;
    if (details is Map && details['code'] != null) {
      code = details['code'] as String;
    }

    switch (code) {
      case 'already-paired':
        message = AppStrings.alreadyPaired;
        break;
      case 'invalid-code':
        message = AppStrings.invalidCode;
        break;
      case 'code-expired':
        message = AppStrings.codeExpired;
        break;
      case 'not-paired':
        message = AppStrings.notPaired;
        break;
      case 'couple-full':
        message = AppStrings.invalidCode;
        break;
      default:
        message = AppStrings.genericError;
        break;
    }

    return PairingException(code, message);
  }
}
