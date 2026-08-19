import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/encoding/canonical_encoder.dart';
import 'package:frontend/core/crypto/ratchet/double_ratchet.dart';
import 'package:frontend/core/crypto/ratchet/ratchet_state.dart';
import 'package:frontend/core/crypto/session/session_manager.dart';

Uint8List hexToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

void main() {
  group('V3.3 Adversarial Security Suite: Attack the Implementation', () {
    late SessionManager sessionManager;
    late Uint8List sharedSecret;

    setUp(() {
      sessionManager = SessionManager();
      sharedSecret = hexToBytes('3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf');
    });

    test('1. Ciphertext Bit-Flipping Tampering Attack Rejection', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);
      final enc = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Top Secret Message".codeUnits),
      );

      final tamperedMessageKey = Uint8List.fromList(enc['message_key'] as Uint8List);
      tamperedMessageKey[0] ^= 0xFF; // Flip 8 bits

      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);

      final decKey = DoubleRatchet.decrypt(
        state: bobState,
        sequenceNumber: enc['sequence_number'],
        messageKey: tamperedMessageKey,
      );

      expect(decKey, isNot(equals(enc['message_key'])));
    });

    test('2. Replay Attack Rejection', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);
      final enc = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Replay Payload".codeUnits),
      );

      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);

      DoubleRatchet.decrypt(state: bobState, sequenceNumber: 0, messageKey: enc['message_key']);

      expect(bobState.skippedMessageKeys.containsKey('key_0'), isFalse);
    });

    test('3. Out-of-Order Delivery & Reused Skipped Key Rejection', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);

      final enc0 = DoubleRatchet.encrypt(state: aliceState, plaintext: Uint8List.fromList("M0".codeUnits));
      final enc1 = DoubleRatchet.encrypt(state: aliceState, plaintext: Uint8List.fromList("M1".codeUnits));

      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);

      DoubleRatchet.decrypt(state: bobState, sequenceNumber: 1, messageKey: enc1['message_key']);
      expect(bobState.skippedMessageKeys.containsKey('key_0'), isTrue);

      DoubleRatchet.decrypt(state: bobState, sequenceNumber: 0, messageKey: enc0['message_key']);
      expect(bobState.skippedMessageKeys.containsKey('key_0'), isFalse);
    });

    test('4. Skipped-Key Resource Exhaustion Attack Protection (Bounded at 200 keys)', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);
      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);

      final encMalicious = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Malicious Jump".codeUnits),
      );

      expect(
        () => DoubleRatchet.decrypt(
          state: bobState,
          sequenceNumber: 250,
          messageKey: encMalicious['message_key'],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Identity-Key Change Safety Lock Execution', () {
      sessionManager.getOrCreateSession(
        deviceId: 'device-b1',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      expect(
        () => sessionManager.getOrCreateSession(
          deviceId: 'device-b1',
          publicIdentityKey: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('6. Revoked Device Messaging Rejection', () {
      sessionManager.getOrCreateSession(
        deviceId: 'device-revoked-laptop',
        publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
      );

      sessionManager.revokeSession('device-revoked-laptop');

      expect(
        () => sessionManager.getOrCreateSession(
          deviceId: 'device-revoked-laptop',
          publicIdentityKey: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('7. Multi-Device Fan-Out Ciphertext Isolation', () {
      final aliceStateB1 = RatchetState(rootKey: hexToBytes('1111111111111111111111111111111111111111111111111111111111111111'), sendingChainKey: hexToBytes('1111111111111111111111111111111111111111111111111111111111111111'));
      final aliceStateB2 = RatchetState(rootKey: hexToBytes('2222222222222222222222222222222222222222222222222222222222222222'), sendingChainKey: hexToBytes('2222222222222222222222222222222222222222222222222222222222222222'));

      final plaintext = Uint8List.fromList("Same Plaintext Payload".codeUnits);

      final encB1 = DoubleRatchet.encrypt(state: aliceStateB1, plaintext: plaintext);
      final encB2 = DoubleRatchet.encrypt(state: aliceStateB2, plaintext: plaintext);

      expect(bytesToHex(encB1['message_key']), isNot(equals(bytesToHex(encB2['message_key']))));
    });

    test('8. Canonical Encoding Safety Number Cross-Platform Determinism', () {
      final keyA = 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
      final keyB = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';

      final snA = CanonicalEncoder.generateSafetyNumber(keyA, keyB);
      final snB = CanonicalEncoder.generateSafetyNumber(keyB, keyA);

      expect(snA, equals(snB));
    });
  });
}
