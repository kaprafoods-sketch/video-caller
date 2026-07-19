import 'package:cloud_functions/cloud_functions.dart';

import '../auth_service.dart';
import '../../l10n/strings.dart';
import '../../models/call_session.dart';
import 'call_service.dart';

const String kCalendarEventsScope =
    'https://www.googleapis.com/auth/calendar.events';

/// A [CallService] implementation backed by `createCall`/`endCall` Cloud
/// Functions. `startCall` obtains a Google OAuth access token scoped for
/// Calendar access, invokes `createCall` to generate a Google Meet link, and
/// returns a [CallSession] whose `joinUri` is expected to be launched by the
/// caller via `url_launcher`.
class MeetLinkCallService implements CallService {
  MeetLinkCallService({
    FirebaseFunctions? functions,
    Future<String> Function(List<String> scopes)? accessTokenProvider,
  })  : _functions = functions ?? FirebaseFunctions.instance,
        _accessTokenProvider =
            accessTokenProvider ?? AuthService().accessTokenForScopes;

  final FirebaseFunctions _functions;
  final Future<String> Function(List<String> scopes) _accessTokenProvider;

  @override
  Future<CallSession> startCall(String coupleId) async {
    try {
      final token = await _accessTokenProvider(const [kCalendarEventsScope]);

      final callable = _functions.httpsCallable('createCall');
      final result = await callable.call<Map<String, dynamic>>({
        'coupleId': coupleId,
        'accessToken': token,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      final meetUrl = data['meetUrl'] as String;
      final callId = data['callId'] as String;

      return CallSession(callId: callId, joinUri: Uri.parse(meetUrl));
    } on CallException {
      rethrow;
    } on CalendarAuthException {
      throw const CallException(
        AppStrings.calendarAccessDenied,
        code: 'calendar-denied',
      );
    } on FirebaseFunctionsException catch (e) {
      throw CallException(AppStrings.callError, code: e.code);
    }
  }

  @override
  Future<void> endCall(String coupleId) async {
    try {
      final callable = _functions.httpsCallable('endCall');
      await callable.call<Map<String, dynamic>>({'coupleId': coupleId});
    } on CallException {
      rethrow;
    } on FirebaseFunctionsException catch (e) {
      throw CallException(AppStrings.callError, code: e.code);
    }
  }
}
