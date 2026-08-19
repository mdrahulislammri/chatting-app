import 'dart:typed_data';
import 'package:crypto/crypto.dart';

class HkdfAdapter {
  static Uint8List deriveKey({
    required Uint8List ikm,
    required Uint8List salt,
    required Uint8List info,
    required int length,
  }) {
    // 1. HKDF-Extract
    final hmacExtract = Hmac(sha256, salt.isEmpty ? Uint8List(32) : salt);
    final prk = hmacExtract.convert(ikm).bytes;

    // 2. HKDF-Expand
    final hmacExpand = Hmac(sha256, prk);
    final okm = Uint8List(length);
    var t = Uint8List(0);
    var generated = 0;
    var counter = 1;

    while (generated < length) {
      final buffer = BytesBuilder();
      buffer.add(t);
      buffer.add(info);
      buffer.addByte(counter);

      t = Uint8List.fromList(hmacExpand.convert(buffer.toBytes()).bytes);
      final todo = (length - generated < 32) ? length - generated : 32;
      okm.setRange(generated, generated + todo, t.sublist(0, todo));

      generated += todo;
      counter++;
    }

    return okm;
  }
}
