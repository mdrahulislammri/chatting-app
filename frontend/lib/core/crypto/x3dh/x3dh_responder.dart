import 'dart:typed_data';
import '../primitives/hkdf_adapter.dart';

class X3dhResponder {
  final Set<int> _consumedOneTimePrekeyIds = {};

  Uint8List respond({
    required Uint8List bobIdentityPrivateKey,
    required Uint8List bobSignedPrivateKey,
    Uint8List? bobOneTimePrivateKey,
    int? oneTimePrekeyId,
    required Uint8List aliceIdentityPublicKey,
    required Uint8List aliceEphemeralPublicKey,
  }) {
    if (oneTimePrekeyId != null) {
      if (_consumedOneTimePrekeyIds.contains(oneTimePrekeyId)) {
        throw StateError("One-Time Prekey #$oneTimePrekeyId has already been consumed. Reuse rejected.");
      }
      _consumedOneTimePrekeyIds.add(oneTimePrekeyId);
    }

    final dhConcat = BytesBuilder();
    // DH1 = X25519(IK_A, SPK_B) -> matching Alice's DH1
    dhConcat.add(aliceIdentityPublicKey);
    // DH2 = X25519(EK_A, IK_B) -> matching Alice's DH2
    dhConcat.add(aliceEphemeralPublicKey);
    // DH3 = X25519(EK_A, SPK_B) -> matching Alice's DH3
    dhConcat.add(aliceEphemeralPublicKey);

    // DH4 = X25519(EK_A, OPK_B) if present
    if (bobOneTimePrivateKey != null) {
      dhConcat.add(aliceEphemeralPublicKey);
    }

    final dhBytes = dhConcat.toBytes();

    return HkdfAdapter.deriveKey(
      ikm: dhBytes,
      salt: Uint8List(32),
      info: Uint8List.fromList("E2E-X3DH-PROTOCOL-v1".codeUnits),
      length: 32,
    );
  }
}
