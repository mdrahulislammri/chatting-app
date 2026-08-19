import 'dart:typed_data';

class X3dhResult {
  final Uint8List sharedSecret;
  final Uint8List ephemeralPublicKey;
  final int? usedOneTimePrekeyId;

  X3dhResult({
    required this.sharedSecret,
    required this.ephemeralPublicKey,
    this.usedOneTimePrekeyId,
  });
}
