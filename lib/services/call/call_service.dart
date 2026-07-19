import '../../models/call_session.dart';

abstract class CallService {
  Future<CallSession> startCall(String coupleId);
  Future<void> endCall(String coupleId);
}
