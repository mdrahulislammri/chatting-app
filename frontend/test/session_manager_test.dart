import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/session/session_manager.dart';

void main() {
  group('V3.1 Step 4: Sesame Session Manager & Identity Key Change Security Matrix', () {
    late SessionManager sessionManager;

    setUp(() {
      sessionManager = SessionManager();
    });

    test('Create Active Session for New Device', () {
      final session = sessionManager.getOrCreateSession(
        deviceId: 'device-win-1',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      expect(session.deviceId, equals('device-win-1'));
      expect(session.state, equals(SessionState.active));
    });

    test('Identity Key Change Suspends Session (Safety Lock Triggered)', () {
      sessionManager.getOrCreateSession(
        deviceId: 'device-win-1',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      expect(
        () => sessionManager.getOrCreateSession(
          deviceId: 'device-win-1',
          publicIdentityKey: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a', // Changed Key!
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('User Approval Restores Session after Safety Key Verification', () {
      sessionManager.getOrCreateSession(
        deviceId: 'device-win-1',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      // Identity changed -> suspended
      try {
        sessionManager.getOrCreateSession(
          deviceId: 'device-win-1',
          publicIdentityKey: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
        );
      } catch (_) {}

      // User approves new key out-of-band / via Safety Number QR
      sessionManager.approveIdentityChange(
        'device-win-1',
        '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
      );

      final restoredSession = sessionManager.getOrCreateSession(
        deviceId: 'device-win-1',
        publicIdentityKey: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
      );

      expect(restoredSession.state, equals(SessionState.active));
    });

    test('Revoked Device Session Rejects Messaging', () {
      sessionManager.getOrCreateSession(
        deviceId: 'device-lost-laptop',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      sessionManager.revokeSession('device-lost-laptop');

      expect(
        () => sessionManager.getOrCreateSession(
          deviceId: 'device-lost-laptop',
          publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
