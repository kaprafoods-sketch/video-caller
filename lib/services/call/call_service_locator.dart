import 'call_service.dart';
// This is the ONLY file permitted to import meet_link_call_service.dart, so
// callers depend only on the CallService interface.
import 'meet_link_call_service.dart';

CallService createCallService() => MeetLinkCallService();
