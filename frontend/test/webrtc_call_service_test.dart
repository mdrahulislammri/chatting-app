import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/call_state.dart';
import 'package:frontend/services/webrtc_call_service.dart';

void main() {
  group('Product Track Module 4: WebRTC Voice & Video Calling Engine Tests', () {
    late WebRtcCallService callService;

    setUp(() {
      callService = WebRtcCallService();
    });

    test('1. Valid Call State Machine Transitions', () {
      var state = CallState.initiating;

      state = callService.validateAndTransition(state, CallState.ringing);
      expect(state, equals(CallState.ringing));

      state = callService.validateAndTransition(state, CallState.connecting);
      expect(state, equals(CallState.connecting));

      state = callService.validateAndTransition(state, CallState.connected);
      expect(state, equals(CallState.connected));

      state = callService.validateAndTransition(state, CallState.ended);
      expect(state, equals(CallState.ended));
    });

    test('2. Invalid Call State Transition Rejection (Fail Closed)', () {
      const endedState = CallState.ended;
      expect(
        () => callService.validateAndTransition(endedState, CallState.connected),
        throwsA(isA<StateError>()),
      );

      const failedState = CallState.failed;
      expect(
        () => callService.validateAndTransition(failedState, CallState.ringing),
        throwsA(isA<StateError>()),
      );
    });

    test('3. CallState Enum Parsing Resolution', () {
      expect(CallState.fromString('initiating'), equals(CallState.initiating));
      expect(CallState.fromString('ringing'), equals(CallState.ringing));
      expect(CallState.fromString('connecting'), equals(CallState.connecting));
      expect(CallState.fromString('connected'), equals(CallState.connected));
      expect(CallState.fromString('ended'), equals(CallState.ended));
      expect(CallState.fromString('failed'), equals(CallState.failed));
    });
  });
}
