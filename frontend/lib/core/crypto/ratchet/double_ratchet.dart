import 'dart:typed_data';
import '../primitives/hkdf_adapter.dart';
import 'ratchet_state.dart';

class DoubleRatchet {
  static const int maxSkippedKeys = 200;

  static Map<String, dynamic> encrypt({
    required RatchetState state,
    required Uint8List plaintext,
  }) {
    if (state.sendingChainKey == null) {
      throw StateError("Sending chain key is not initialized.");
    }

    final messageKey = HkdfAdapter.deriveKey(
      ikm: state.sendingChainKey!,
      salt: Uint8List(0),
      info: Uint8List.fromList("E2E-MESSAGE-KEY-v1".codeUnits),
      length: 32,
    );

    state.sendingChainKey = HkdfAdapter.deriveKey(
      ikm: state.sendingChainKey!,
      salt: Uint8List(0),
      info: Uint8List.fromList("E2E-NEXT-CHAIN-KEY-v1".codeUnits),
      length: 32,
    );

    final seq = state.sequenceNumber;
    state.sequenceNumber++;

    return {
      'sequence_number': seq,
      'message_key': messageKey,
      'plaintext': plaintext,
    };
  }

  static Uint8List decrypt({
    required RatchetState state,
    required int sequenceNumber,
    required Uint8List messageKey,
  }) {
    // 1. Check Skipped Message Keys for Out-of-Order / Retried delivery
    final keyId = "key_$sequenceNumber";
    if (state.skippedMessageKeys.containsKey(keyId)) {
      state.skippedMessageKeys.remove(keyId);
      return messageKey;
    }

    // 2. Advance receiving chain if needed
    if (state.receivingChainKey != null) {
      while (state.sequenceNumber < sequenceNumber) {
        if (state.skippedMessageKeys.length >= maxSkippedKeys) {
          throw StateError("Skipped message keys limit reached ($maxSkippedKeys).");
        }

        final skippedKey = HkdfAdapter.deriveKey(
          ikm: state.receivingChainKey!,
          salt: Uint8List(0),
          info: Uint8List.fromList("E2E-MESSAGE-KEY-v1".codeUnits),
          length: 32,
        );

        state.skippedMessageKeys["key_${state.sequenceNumber}"] = skippedKey;

        state.receivingChainKey = HkdfAdapter.deriveKey(
          ikm: state.receivingChainKey!,
          salt: Uint8List(0),
          info: Uint8List.fromList("E2E-NEXT-CHAIN-KEY-v1".codeUnits),
          length: 32,
        );

        state.sequenceNumber++;
      }
    }

    return messageKey;
  }
}
