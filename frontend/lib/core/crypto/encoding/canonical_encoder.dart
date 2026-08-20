import 'package:crypto/crypto.dart';

class CanonicalEncoder {
  static const int protocolVersion = 1;

  static String sortAndEncodeIdentityKeys(String keyA, String keyB) {
    final sorted = [keyA.toLowerCase(), keyB.toLowerCase()]..sort();
    final hexString = '01${sorted[0]}${sorted[1]}';
    return hexString;
  }

  static String generateSafetyNumber(String keyA, String keyB) {
    final hexString = sortAndEncodeIdentityKeys(keyA, keyB);
    final bytes = _hexToBytes(hexString);
    final digest = sha512.convert(bytes);
    final digestHex = digest.toString();

    final List<String> blocks = [];
    for (var i = 0; i < 30; i += 5) {
      final sub = digestHex.substring(i, i + 5);
      final val = int.parse(sub, radix: 16) % 100000;
      blocks.add(val.toString().padLeft(5, '0'));
    }

    return blocks.join(' ');
  }

  static String generateFingerprint(String key) {
    final bytes = _hexToBytes(key.toLowerCase());
    final digest = sha256.convert(bytes.isEmpty ? [0] : bytes);
    return digest.toString();
  }

  static List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }
}
