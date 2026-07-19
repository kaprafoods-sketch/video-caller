import '../../models/call_session.dart';

abstract class CallService {
  Future<CallSession> startCall(String coupleId);
  Future<void> endCall(String coupleId);
}

/// A backend-agnostic error surfaced by any [CallService] implementation.
/// UI code should catch this and show [message]; it must never need to know
/// which call backend (Meet, WebRTC, …) produced it.
class CallException implements Exception {
  const CallException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
