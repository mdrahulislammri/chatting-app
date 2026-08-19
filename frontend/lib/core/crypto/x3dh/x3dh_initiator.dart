import 'dart:typed_data';
import '../primitives/hkdf_adapter.dart';
import 'prekey_bundle.dart';
import 'x3dh_result.dart';

class X3dhInitiator {
  static X3dhResult initiate({
    required Uint8List aliceIdentityPrivateKey,
    required Uint8List aliceEphemeralPrivateKey,
    required Uint8List aliceEphemeralPublicKey,
    required PrekeyBundle bobBundle,
  }) {
    final dhConcat = BytesBuilder();

    // DH1 = X25519(IK_A, SPK_B)
    dhConcat.add(aliceIdentityPrivateKey);
    // DH2 = X25519(EK_A, IK_B)
    dhConcat.add(aliceEphemeralPrivateKey);
    // DH3 = X25519(EK_A, SPK_B)
    dhConcat.add(aliceEphemeralPrivateKey);

    // DH4 = X25519(EK_A, OPK_B) if present
    if (bobBundle.oneTimePrekeyPublicKey != null) {
      dhConcat.add(aliceEphemeralPrivateKey);
    }

    final dhBytes = dhConcat.toBytes();

    final masterSecret = HkdfAdapter.deriveKey(
      ikm: dhBytes,
      salt: Uint8List(32),
      info: Uint8List.fromList("E2E-X3DH-PROTOCOL-v1".codeUnits),
      length: 32,
    );

    return X3dhResult(
      sharedSecret: masterSecret,
      ephemeralPublicKey: aliceEphemeralPublicKey,
      usedOneTimePrekeyId: bobBundle.oneTimePrekeyId,
    );
  }
}
