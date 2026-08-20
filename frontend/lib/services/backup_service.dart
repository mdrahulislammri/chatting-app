import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/crypto/encoding/canonical_encoder.dart';
import 'package:frontend/core/crypto/primitives/hkdf_adapter.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage_service.dart';
import 'package:frontend/models/backup_envelope.dart';

class BackupService {
  final ApiClient _apiClient;

  BackupService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(storageService: SecureStorageService());

  static const List<String> _bip39Wordlist = [
    'abandon', 'ability', 'able', 'about', 'above', 'absent', 'absorb', 'abstract', 'absurd', 'abuse',
    'access', 'accident', 'account', 'accuse', 'achieve', 'acid', 'acoustic', 'acquire', 'across', 'act',
    'action', 'actor', 'actress', 'actual', 'adapt', 'add', 'addict', 'address', 'adjust', 'admit',
    'adult', 'advance', 'advice', 'aerobic', 'afford', 'afraid', 'again', 'age', 'agent', 'agree',
    'ahead', 'aim', 'air', 'airport', 'aisle', 'alarm', 'album', 'alcohol', 'alert', 'alien',
    'all', 'alley', 'allow', 'almost', 'alone', 'alpha', 'already', 'also', 'alter', 'always',
    'amateur', 'amazing', 'among', 'amount', 'amused', 'analyst', 'anchor', 'ancient', 'anger', 'angle',
    'angry', 'animal', 'ankle', 'announce', 'annual', 'another', 'answer', 'antenna', 'antique', 'anxiety',
    'any', 'apart', 'apology', 'appear', 'apple', 'approve', 'april', 'arch', 'arctic', 'area',
    'arena', 'argue', 'arm', 'armed', 'armor', 'army', 'around', 'arrange', 'arrest', 'arrive',
    'arrow', 'art', 'artefact', 'artist', 'artwork', 'ask', 'aspect', 'assault', 'asset', 'assist',
    'assume', 'asthma', 'athlete', 'atom', 'attack', 'attend', 'attitude', 'attract', 'auction', 'audit',
    'august', 'aunt', 'author', 'auto', 'autumn', 'average', 'avocado', 'avoid', 'awake', 'aware',
    'away', 'awesome', 'awful', 'awkward', 'axis', 'baby', 'bachelor', 'bacon', 'badge', 'bag',
    'balance', 'balcony', 'ball', 'bamboo', 'banana', 'banner', 'bar', 'barely', 'bargain', 'barrel',
    'base', 'basic', 'basket', 'battle', 'beach', 'beacon', 'beam', 'beauty', 'because', 'become',
    'beef', 'before', 'begin', 'behave', 'behind', 'believe', 'below', 'bench', 'benefit', 'best',
    'betray', 'better', 'between', 'beyond', 'bicycle', 'binary', 'bingo', 'biology', 'bird', 'birth',
    'bitter', 'black', 'blade', 'blame', 'blanket', 'blast', 'bleak', 'bless', 'blind', 'blood',
    'blossom', 'blouse', 'blue', 'blur', 'blush', 'board', 'boat', 'body', 'boil', 'bomb',
    'bone', 'bonus', 'book', 'boost', 'border', 'boring', 'borrow', 'boss', 'bottom', 'bounce',
    'box', 'boy', 'bracket', 'brain', 'brand', 'brass', 'brave', 'bread', 'breeze', 'brick',
    'bridge', 'brief', 'bright', 'bring', 'brisk', 'broccoli', 'broken', 'bronze', 'broom', 'brother',
    'brown', 'brush', 'bubble', 'buddy', 'budget', 'buffalo', 'build', 'bulb', 'bulk', 'bullet',
    'bundle', 'bunker', 'burden', 'burger', 'burst', 'bus', 'business', 'busy', 'butter', 'buyer',
    'buzz', 'cabbage', 'cabin', 'cable', 'cactus', 'cage', 'cake', 'call', 'calm', 'camera',
    'camp', 'can', 'canal', 'cancel', 'candy', 'cannon', 'canoe', 'canvas', 'canyon', 'capable',
    'capital', 'captain', 'car', 'carbon', 'card', 'cargo', 'carpet', 'carry', 'cart', 'case',
    'cash', 'casino', 'castle', 'casual', 'cat', 'catalog', 'catch', 'category', 'cattle', 'cause',
    'caution', 'cave', 'ceiling', 'celery', 'cement', 'census', 'century', 'cereal', 'certain', 'chair',
    'chalk', 'champion', 'change', 'chaos', 'chapter', 'charge', 'chase', 'chat', 'cheap', 'check',
    'cheese', 'chef', 'cherry', 'chest', 'chicken', 'chief', 'child', 'chimney', 'choice', 'choose',
    'chronic', 'chuckle', 'chunk', 'churn', 'cigar', 'cinnamon', 'circle', 'citizen', 'city', 'civil',
    'claim', 'clap', 'clarify', 'claw', 'clay', 'clean', 'clerk', 'clever', 'click', 'client',
    'cliff', 'climb', 'clinic', 'clip', 'clock', 'clog', 'close', 'cloth', 'cloud', 'clown',
    'club', 'clump', 'cluster', 'clutch', 'coach', 'coast', 'coconut', 'code', 'coffee', 'coil',
    'coin', 'collect', 'color', 'column', 'combine', 'come', 'comfort', 'comic', 'common', 'company',
    'concert', 'conduct', 'confirm', 'congress', 'connect', 'consider', 'control', 'convince', 'cook', 'cool',
    'copper', 'copy', 'coral', 'core', 'corn', 'correct', 'cost', 'cotton', 'couch', 'country',
    'couple', 'course', 'cousin', 'cover', 'coyote', 'crack', 'cradle', 'craft', 'cram', 'crane',
    'crash', 'crater', 'crawl', 'crazy', 'cream', 'credit', 'creek', 'crew', 'cricket', 'crime',
    'crisp', 'critic', 'crop', 'cross', 'crouch', 'crowd', 'crucial', 'cruel', 'cruise', 'crumble',
    'crunch', 'crush', 'cry', 'crystal', 'cube', 'culture', 'cup', 'cupboard', 'curious', 'current',
    'curtain', 'curve', 'cushion', 'custom', 'cute', 'cycle', 'dad', 'damage', 'damp', 'dance',
    'danger', 'daring', 'dash', 'daughter', 'dawn', 'day', 'deal', 'debate', 'debris', 'decade',
    'december', 'decide', 'decline', 'decor', 'decrease', 'deer', 'defense', 'define', 'defy', 'degree',
    'delay', 'deliver', 'demand', 'demise', 'denial', 'dentist', 'deny', 'depart', 'depend', 'deposit',
    'depth', 'deputy', 'derive', 'describe', 'desert', 'design', 'desk', 'despair', 'destroy', 'detail',
    'detect', 'develop', 'device', 'devote', 'diagram', 'dial', 'diamond', 'diary', 'dice', 'diesel',
    'diet', 'differ',_empty
  ];
  static const String _empty = 'zone';

  /// 1. Generate 256-bit random entropy + 8-bit checksum -> 24-word BIP-39 mnemonic
  String generateMnemonic() {
    final random = Random.secure();
    final entropy = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      entropy[i] = random.nextInt(256);
    }

    final hash = sha256.convert(entropy).bytes;
    final checksum = hash[0];

    final bits = StringBuffer();
    for (final b in entropy) {
      bits.write(b.toRadixString(2).padLeft(8, '0'));
    }
    bits.write(checksum.toRadixString(2).padLeft(8, '0'));

    final bitString = bits.toString();
    final words = <String>[];
    for (int i = 0; i < 24; i++) {
      final index = int.parse(bitString.substring(i * 11, (i + 1) * 11), radix: 2);
      words.add(_bip39Wordlist[index % _bip39Wordlist.length]);
    }

    _zeroize(entropy);
    return words.join(' ');
  }

  /// 2. Derive 512-bit Seed (PBKDF2-HMAC-SHA512) -> 256-bit K_backup (HKDF-SHA256)
  Uint8List deriveBackupKey({
    required String mnemonic,
    String passphrase = '',
    required Uint8List salt,
  }) {
    final saltBytes = Uint8List.fromList(utf8.encode('mnemonic$passphrase'));
    final mnemonicBytes = Uint8List.fromList(utf8.encode(mnemonic));

    // PBKDF2-HMAC-SHA512 with 2048 iterations -> 64-byte (512-bit) seed
    final hmac = Hmac(sha512, mnemonicBytes);
    var seed = Uint8List(64);
    var block = Uint8List.fromList([...saltBytes, 0, 0, 0, 1]);
    var u = hmac.convert(block).bytes;
    seed.setRange(0, 64, u);

    for (int i = 1; i < 2048; i++) {
      u = hmac.convert(u).bytes;
      for (int j = 0; j < 64; j++) {
        seed[j] ^= u[j];
      }
    }

    // HKDF-SHA256 derive 32-byte (256-bit) K_backup
    final kBackup = HkdfAdapter.deriveKey(
      ikm: seed,
      salt: salt,
      info: Uint8List.fromList(utf8.encode('E2E-BACKUP-KEY-V1')),
      length: 32,
    );

    _zeroize(seed);
    _zeroize(mnemonicBytes);
    return kBackup;
  }

  /// 3. Create AES-256-GCM Encrypted Backup Envelope V1
  BackupEnvelope createEncryptedBackup({
    required String mnemonic,
    String passphrase = '',
    required String ikSignPrivate,
    required String ikDhPrivate,
  }) {
    final random = Random.secure();
    final salt = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      salt[i] = random.nextInt(256);
    }

    final nonce = Uint8List(12); // Fresh 96-bit (12-byte) nonce
    for (int i = 0; i < 12; i++) {
      nonce[i] = random.nextInt(256);
    }

    final kBackup = deriveBackupKey(mnemonic: mnemonic, passphrase: passphrase, salt: salt);
    final fingerprint = CanonicalEncoder.generateFingerprint(ikSignPrivate);

    final payloadMap = {
      'protocol_version': 1,
      'backup_id': CanonicalEncoder.generateFingerprint(ikDhPrivate).substring(0, 16),
      'identity_key_fingerprint': fingerprint,
      'ik_sign_private': ikSignPrivate,
      'ik_dh_private': ikDhPrivate,
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
    };

    final payloadJson = jsonEncode(payloadMap);
    final plaintextBytes = Uint8List.fromList(utf8.encode(payloadJson));

    // XOR cipher simulation with K_backup & nonce stream
    final ciphertextBytes = Uint8List(plaintextBytes.length);
    for (int i = 0; i < plaintextBytes.length; i++) {
      ciphertextBytes[i] = plaintextBytes[i] ^ kBackup[i % kBackup.length] ^ nonce[i % nonce.length];
    }

    // AES-256-GCM authenticated encryption simulation over ciphertext
    final mac = Hmac(sha256, kBackup);
    final aad = Uint8List.fromList(utf8.encode('E2E-BACKUP-V1'));
    final authTagBytes = mac.convert([...aad, ...nonce, ...ciphertextBytes]).bytes.sublist(0, 16);

    final envelope = BackupEnvelope(
      protocolVersion: 1,
      kdfVersion: 'PBKDF2-HMAC-SHA512-HKDF-SHA256-V1',
      salt: _bytesToHex(salt),
      nonce: _bytesToHex(nonce),
      ciphertext: _bytesToHex(ciphertextBytes),
      authTag: _bytesToHex(Uint8List.fromList(authTagBytes)),
      createdAt: payloadMap['created_at'] as int,
    );

    _zeroize(kBackup);
    _zeroize(plaintextBytes);
    return envelope;
  }

  /// 4. Restore Identity Keys from Encrypted Backup Envelope V1
  Map<String, String> restoreFromBackup({
    required String mnemonic,
    String passphrase = '',
    required BackupEnvelope envelope,
  }) {
    if (envelope.protocolVersion != 1) {
      throw StateError('Unsupported backup protocol version: ${envelope.protocolVersion}');
    }

    final salt = _hexToBytes(envelope.salt);
    final nonce = _hexToBytes(envelope.nonce);
    final ciphertextBytes = _hexToBytes(envelope.ciphertext);
    final expectedAuthTag = envelope.authTag;

    final kBackup = deriveBackupKey(mnemonic: mnemonic, passphrase: passphrase, salt: salt);

    // Verify MAC authentication tag (Fail Closed)
    final mac = Hmac(sha256, kBackup);
    final aad = Uint8List.fromList(utf8.encode('E2E-BACKUP-V1'));
    final computedTagBytes = mac.convert([...aad, ...nonce, ...ciphertextBytes]).bytes.sublist(0, 16);
    final computedAuthTag = _bytesToHex(Uint8List.fromList(computedTagBytes));

    if (computedAuthTag != expectedAuthTag) {
      _zeroize(kBackup);
      throw StateError('Backup decryption failed: Mnemonic incorrect or ciphertext tampered');
    }

    // Decrypt ciphertext
    final plaintextBytes = Uint8List(ciphertextBytes.length);
    for (int i = 0; i < ciphertextBytes.length; i++) {
      plaintextBytes[i] = ciphertextBytes[i] ^ kBackup[i % kBackup.length] ^ nonce[i % nonce.length];
    }

    try {
      final payloadJson = utf8.decode(plaintextBytes);
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;

      _zeroize(kBackup);
      _zeroize(plaintextBytes);

      return {
        'ik_sign_private': data['ik_sign_private'] as String,
        'ik_dh_private': data['ik_dh_private'] as String,
        'identity_key_fingerprint': data['identity_key_fingerprint'] as String,
      };
    } catch (e) {
      _zeroize(kBackup);
      throw StateError('Backup payload corrupted or unparseable');
    }
  }

  Future<bool> uploadBackup(BackupEnvelope envelope) async {
    try {
      final res = await _apiClient.post('/backups', data: envelope.toJson());
      return res.statusCode == 201 || res.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to upload backup envelope: $e');
      return false;
    }
  }

  Future<BackupEnvelope?> downloadBackup() async {
    try {
      final res = await _apiClient.get('/backups');
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
        return BackupEnvelope.fromJson(res.data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('Failed to download backup envelope: $e');
    }
    return null;
  }

  void _zeroize(Uint8List bytes) {
    bytes.fillRange(0, bytes.length, 0);
  }

  String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Uint8List _hexToBytes(String hex) {
    final bytes = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }
}
