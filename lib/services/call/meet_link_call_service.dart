import '../../models/call_session.dart';
import 'call_service.dart';

/// A [CallService] implementation that will generate a shareable meeting
/// link. It will use a `createCall` Cloud Function plus `url_launcher` to
/// open the generated link once that feature is implemented.
class MeetLinkCallService implements CallService {
  @override
  Future<CallSession> startCall(String coupleId) {
    throw UnimplementedError('Meet link generation ships in a later feature');
  }

  @override
  Future<void> endCall(String coupleId) {
    throw UnimplementedError('Meet link generation ships in a later feature');
  }
}
