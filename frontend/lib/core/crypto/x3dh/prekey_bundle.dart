import 'dart:typed_data';

class PrekeyBundle {
  final String deviceId;
  final Uint8List identityPublicKey; // Ed25519 / X25519 Identity Key
  final Uint8List signedPrekeyPublicKey; // X25519 Signed Prekey
  final Uint8List signedPrekeySignature; // Ed25519 Signature over SPK
  final Uint8List? oneTimePrekeyPublicKey; // Optional X25519 OPK
  final int? oneTimePrekeyId;

  PrekeyBundle({
    required this.deviceId,
    required this.identityPublicKey,
    required this.signedPrekeyPublicKey,
    required this.signedPrekeySignature,
    this.oneTimePrekeyPublicKey,
    this.oneTimePrekeyId,
  });
}
