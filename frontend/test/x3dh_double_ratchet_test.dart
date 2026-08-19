import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/ratchet/double_ratchet.dart';
import 'package:frontend/core/crypto/ratchet/ratchet_state.dart';
import 'package:frontend/core/crypto/x3dh/prekey_bundle.dart';
import 'package:frontend/core/crypto/x3dh/x3dh_initiator.dart';
import 'package:frontend/core/crypto/x3dh/x3dh_responder.dart';

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
  group('V3.1 Step 3: X3DH Handshake & Double Ratchet Engine Test Matrix', () {
    test('X3DH Shared Secret Derivation Equality (Alice & Bob derive identical SK)', () {
      final aliceIkPriv = hexToBytes('77076d0a7318a57d3c16c17251b26645df4c2f87ebd09f56e73163e81014d06c');
      final aliceEkPriv = hexToBytes('5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb');
      final aliceEkPub = hexToBytes('8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a');

      final bobIkPriv = hexToBytes('5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb');
      final bobSpkPriv = hexToBytes('77076d0a7318a57d3c16c17251b26645df4c2f87ebd09f56e73163e81014d06c');
      final bobOpkPriv = hexToBytes('4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742');

      final bobBundle = PrekeyBundle(
        deviceId: 'bob-device-1',
        identityPublicKey: hexToBytes('de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f'),
        signedPrekeyPublicKey: hexToBytes('8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a'),
        signedPrekeySignature: hexToBytes('e5934160d354b7cb35d0649605858a8177350084663d6757254085d2100046d55703530555669473c00419c42821a979201c10757a3e758416d634be9c6e3926'),
        oneTimePrekeyPublicKey: hexToBytes('de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f'),
        oneTimePrekeyId: 42,
      );

      final aliceResult = X3dhInitiator.initiate(
        aliceIdentityPrivateKey: aliceIkPriv,
        aliceEphemeralPrivateKey: aliceEkPriv,
        aliceEphemeralPublicKey: aliceEkPub,
        bobBundle: bobBundle,
      );

      final responder = X3dhResponder();
      final bobSecret = responder.respond(
        bobIdentityPrivateKey: bobIkPriv,
        bobSignedPrivateKey: bobSpkPriv,
        bobOneTimePrivateKey: bobOpkPriv,
        oneTimePrekeyId: 42,
        aliceIdentityPublicKey: aliceIkPriv,
        aliceEphemeralPublicKey: aliceEkPriv,
      );

      expect(bytesToHex(aliceResult.sharedSecret), equals(bytesToHex(bobSecret)));
    });

    test('X3DH One-Time Prekey Reuse Rejection (Attempting to reuse consumed OPK #42 throws exception)', () {
      final responder = X3dhResponder();

      responder.respond(
        bobIdentityPrivateKey: Uint8List(32),
        bobSignedPrivateKey: Uint8List(32),
        bobOneTimePrivateKey: Uint8List(32),
        oneTimePrekeyId: 42,
        aliceIdentityPublicKey: Uint8List(32),
        aliceEphemeralPublicKey: Uint8List(32),
      );

      expect(
        () => responder.respond(
          bobIdentityPrivateKey: Uint8List(32),
          bobSignedPrivateKey: Uint8List(32),
          bobOneTimePrivateKey: Uint8List(32),
          oneTimePrekeyId: 42,
          aliceIdentityPublicKey: Uint8List(32),
          aliceEphemeralPublicKey: Uint8List(32),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Double Ratchet State Step & Out-of-Order Skipped Message Key Handling', () {
      final sharedSecret = hexToBytes('3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf');

      final aliceState = RatchetState(
        rootKey: sharedSecret,
        sendingChainKey: sharedSecret,
      );

      final bobState = RatchetState(
        rootKey: sharedSecret,
        receivingChainKey: sharedSecret,
      );

      final enc0 = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Message 0".codeUnits),
      );
      expect(enc0['sequence_number'], equals(0));

      final enc1 = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Message 1".codeUnits),
      );
      expect(enc1['sequence_number'], equals(1));

      final dec1 = DoubleRatchet.decrypt(
        state: bobState,
        sequenceNumber: enc1['sequence_number'],
        messageKey: enc1['message_key'],
      );
      expect(dec1, equals(enc1['message_key']));

      expect(bobState.skippedMessageKeys.containsKey('key_0'), isTrue);

      final dec0 = DoubleRatchet.decrypt(
        state: bobState,
        sequenceNumber: enc0['sequence_number'],
        messageKey: enc0['message_key'],
      );
      expect(dec0, equals(enc0['message_key']));
      expect(bobState.skippedMessageKeys.containsKey('key_0'), isFalse);
    });
  });
}
