import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/ratchet/double_ratchet.dart';
import 'package:frontend/core/crypto/ratchet/ratchet_state.dart';
import 'package:frontend/core/crypto/session/session_manager.dart';
import 'package:frontend/core/crypto/x3dh/x3dh_responder.dart';

Uint8List hexToBytes(String hex) {
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < hex.length; i += 2) {
    bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
  }
  return bytes;
}

void main() {
  group('V3.3.1 Property & State Machine Mutation Test Suite with Deterministic Seed', () {
    late Uint8List sharedSecret;
    const int seedValue = 0xE2E2026;

    setUp(() {
      sharedSecret = hexToBytes('3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf');
    });

    test('1. Validate Regression Test Corpus Files', () {
      final regDir = Directory('test/security/regressions');
      expect(regDir.existsSync(), isTrue);

      final files = regDir.listSync().whereType<File>().toList();
      expect(files.length, greaterThanOrEqualTo(4));

      for (final f in files) {
        final content = jsonDecode(f.readAsStringSync());
        expect(content['id'], isNotEmpty);
        expect(content['seed'], equals('0xE2E2026'));
        expect(content['expected_result'], isNotEmpty);
      }
    });

    test('2. Fuzzing X3DH Inputs with Malformed & Truncated Keys', () {
      final responder = X3dhResponder();

      expect(
        () => responder.respond(
          bobIdentityPrivateKey: Uint8List(16),
          bobSignedPrivateKey: Uint8List(32),
          bobOneTimePrivateKey: Uint8List(32),
          oneTimePrekeyId: 101,
          aliceIdentityPublicKey: Uint8List(32),
          aliceEphemeralPublicKey: Uint8List(32),
        ),
        returnsNormally,
      );

      responder.respond(
        bobIdentityPrivateKey: Uint8List(32),
        bobSignedPrivateKey: Uint8List(32),
        bobOneTimePrivateKey: Uint8List(32),
        oneTimePrekeyId: 202,
        aliceIdentityPublicKey: Uint8List(32),
        aliceEphemeralPublicKey: Uint8List(32),
      );

      expect(
        () => responder.respond(
          bobIdentityPrivateKey: Uint8List(32),
          bobSignedPrivateKey: Uint8List(32),
          bobOneTimePrivateKey: Uint8List(32),
          oneTimePrekeyId: 202,
          aliceIdentityPublicKey: Uint8List(32),
          aliceEphemeralPublicKey: Uint8List(32),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('3. Double Ratchet Fuzzing: Malformed Sequence Numbers & Corrupted Envelopes', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);
      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);

      final enc = DoubleRatchet.encrypt(
        state: aliceState,
        plaintext: Uint8List.fromList("Payload".codeUnits),
      );

      final resNeg = DoubleRatchet.decrypt(
        state: bobState,
        sequenceNumber: -1,
        messageKey: enc['message_key'],
      );
      expect(resNeg, equals(enc['message_key']));

      expect(
        () => DoubleRatchet.decrypt(
          state: bobState,
          sequenceNumber: 99999,
          messageKey: enc['message_key'],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('4. Reproducible State Machine Mutation Run (Seed: 0xE2E2026)', () {
      final aliceState = RatchetState(rootKey: sharedSecret, sendingChainKey: sharedSecret);
      final bobState = RatchetState(rootKey: sharedSecret, receivingChainKey: sharedSecret);
      final sessionMgr = SessionManager();

      final rng = Random(seedValue);
      int expectedSeq = 0;
      final List<String> mutationSequence = [];

      try {
        for (var step = 0; step < 50; step++) {
          final op = rng.nextInt(4);
          mutationSequence.add("Step $step: Op $op");

          if (op == 0) {
            final enc = DoubleRatchet.encrypt(
              state: aliceState,
              plaintext: Uint8List.fromList("Step $step".codeUnits),
            );
            expect(enc['sequence_number'], equals(expectedSeq));
            expectedSeq++;
            expect(aliceState.sequenceNumber, equals(expectedSeq));
          } else if (op == 1) {
            if (expectedSeq > bobState.sequenceNumber) {
              DoubleRatchet.decrypt(
                state: bobState,
                sequenceNumber: bobState.sequenceNumber,
                messageKey: sharedSecret,
              );
            }
          } else if (op == 2) {
            final replayedSeq = (bobState.sequenceNumber > 0) ? bobState.sequenceNumber - 1 : 0;
            expect(bobState.skippedMessageKeys.containsKey('key_$replayedSeq'), isFalse);
          } else if (op == 3) {
            sessionMgr.getOrCreateSession(deviceId: 'dev-$step', publicIdentityKey: 'key-$step');
            sessionMgr.revokeSession('dev-$step');
            expect(
              () => sessionMgr.getOrCreateSession(deviceId: 'dev-$step', publicIdentityKey: 'key-$step'),
              throwsA(isA<StateError>()),
            );
          }
        }
      } catch (e) {
        fail("State Machine Failure! Seed: 0xE2E2026, Last Sequence: $mutationSequence, Error: $e");
      }
    });
  });
}
