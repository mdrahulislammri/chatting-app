import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/encoding/canonical_encoder.dart';
import 'package:frontend/core/crypto/primitives/hkdf_adapter.dart';

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
  group('V3.1 Cryptographic Reference Vector Suite & Adapter Layer Verification', () {
    late Map<String, dynamic> suite;

    setUpAll(() {
      final file = File('test/crypto_test_vectors.json');
      expect(file.existsSync(), isTrue, reason: 'Test vector harness file must exist.');
      final jsonString = file.readAsStringSync();
      suite = jsonDecode(jsonString);
    });

    test('Verify Official Test Vector Suite Schema', () {
      expect(suite['version'], equals(1));
      expect(suite['encoding_convention'], equals('hex'));
      final List vectors = suite['vectors'];
      expect(vectors.length, equals(5));
    });

    test('Validate RFC 5869 HKDF-SHA256 Test Case 1 Vector against HkdfAdapter', () {
      final v = (suite['vectors'] as List).firstWhere((item) => item['id'] == 'rfc5869-hkdf-sha256-001');

      final ikm = hexToBytes(v['inputs']['ikm']);
      final salt = hexToBytes(v['inputs']['salt']);
      final info = hexToBytes(v['inputs']['info']);
      final length = v['inputs']['length'] as int;

      final derivedOkm = HkdfAdapter.deriveKey(ikm: ikm, salt: salt, info: info, length: length);
      final derivedOkmHex = bytesToHex(derivedOkm);

      expect(derivedOkmHex, equals(v['expected_okm']));
    });

    test('Validate Canonical Key Ordering & Safety Number against CanonicalEncoder', () {
      final v = (suite['vectors'] as List).firstWhere((item) => item['id'] == 'canonical-encoding-v1-001');

      final keyA = v['inputs']['identity_key_a'] as String;
      final keyB = v['inputs']['identity_key_b'] as String;

      final canonicalHex = CanonicalEncoder.sortAndEncodeIdentityKeys(keyA, keyB);
      expect(canonicalHex, equals(v['expected_canonical_hex']));

      final safetyNumber = CanonicalEncoder.generateSafetyNumber(keyA, keyB);
      expect(safetyNumber.split(' ').length, equals(6));
    });
  });
}
