import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/backup_envelope.dart';
import 'package:frontend/services/backup_service.dart';

void main() {
  group('Product Track Module 3: AES-256-GCM Encrypted Backup & Recovery Engine Tests', () {
    late BackupService backupService;
    const ikSignPrivate = 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
    const ikDhPrivate = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';

    setUp(() {
      backupService = BackupService();
    });

    test('1. Standards-Compliant BIP-39 24-Word Mnemonic Generation & Validation', () {
      final mnemonic = backupService.generateMnemonic();
      final words = mnemonic.split(' ');

      expect(words.length, equals(24));
      expect(words.every((w) => w.isNotEmpty), isTrue);
      expect(backupService.validateMnemonic(mnemonic), isTrue);

      // Verify invalid mnemonic checksum or length rejection
      expect(backupService.validateMnemonic('invalid word list'), isFalse);
    });

    test('2. Real AES-256-GCM Backup Envelope V1 Creation & Identity Restoration', () {
      final mnemonic = backupService.generateMnemonic();

      final envelope = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        passphrase: 'secure-user-passphrase',
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      expect(envelope.protocolVersion, equals(1));
      expect(envelope.kdfVersion, equals('PBKDF2-HMAC-SHA512-HKDF-SHA256-AES256GCM-V1'));
      expect(envelope.salt.length, equals(64)); // 32 bytes hex
      expect(envelope.nonce.length, equals(24)); // 12 bytes hex (96-bit)
      expect(envelope.authTag.length, equals(32)); // 16 bytes hex

      final restored = backupService.restoreFromBackup(
        mnemonic: mnemonic,
        passphrase: 'secure-user-passphrase',
        envelope: envelope,
      );

      expect(restored['ik_sign_private'], equals(ikSignPrivate));
      expect(restored['ik_dh_private'], equals(ikDhPrivate));
      expect(restored['identity_key_fingerprint'], isNotNull);
    });

    test('3. Adversarial Attack: Wrong Mnemonic Rejection (Fail Closed)', () {
      final mnemonicCorrect = backupService.generateMnemonic();
      final mnemonicWrong = backupService.generateMnemonic();

      final envelope = backupService.createEncryptedBackup(
        mnemonic: mnemonicCorrect,
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      expect(
        () => backupService.restoreFromBackup(mnemonic: mnemonicWrong, envelope: envelope),
        throwsA(isA<StateError>()),
      );
    });

    test('4. Adversarial Attack: Tampered Auth Tag Rejection (AES-GCM Fail Closed)', () {
      final mnemonic = backupService.generateMnemonic();

      final envelope = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      final tamperedTag = envelope.authTag.startsWith('00')
          ? 'ff${envelope.authTag.substring(2)}'
          : '00${envelope.authTag.substring(2)}';

      final tamperedEnvelope = BackupEnvelope(
        protocolVersion: envelope.protocolVersion,
        kdfVersion: envelope.kdfVersion,
        salt: envelope.salt,
        nonce: envelope.nonce,
        ciphertext: envelope.ciphertext,
        authTag: tamperedTag,
        createdAt: envelope.createdAt,
      );

      expect(
        () => backupService.restoreFromBackup(mnemonic: mnemonic, envelope: tamperedEnvelope),
        throwsA(isA<StateError>()),
      );
    });

    test('5. Adversarial Attack: Ciphertext Bit-Flipping Rejection (AES-GCM Fail Closed)', () {
      final mnemonic = backupService.generateMnemonic();

      final envelope = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      final tamperedCiphertext = envelope.ciphertext.startsWith('00')
          ? 'ff${envelope.ciphertext.substring(2)}'
          : '00${envelope.ciphertext.substring(2)}';

      final tamperedEnvelope = BackupEnvelope(
        protocolVersion: envelope.protocolVersion,
        kdfVersion: envelope.kdfVersion,
        salt: envelope.salt,
        nonce: envelope.nonce,
        ciphertext: tamperedCiphertext,
        authTag: envelope.authTag,
        createdAt: envelope.createdAt,
      );

      expect(
        () => backupService.restoreFromBackup(mnemonic: mnemonic, envelope: tamperedEnvelope),
        throwsA(isA<StateError>()),
      );
    });

    test('6. Unsupported Protocol Version Rejection', () {
      final invalidJson = {
        'protocol_version': 2,
        'kdf_version': 'V2',
        'salt': '00',
        'nonce': '00',
        'ciphertext': '00',
        'auth_tag': '00',
        'created_at': 123,
      };

      expect(() => BackupEnvelope.fromJson(invalidJson), throwsA(isA<StateError>()));
    });

    test('7. Per-Backup Random Salt & Fresh Nonce Uniqueness Verification', () {
      final mnemonic = backupService.generateMnemonic();

      final envelope1 = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      final envelope2 = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        ikSignPrivate: ikSignPrivate,
        ikDhPrivate: ikDhPrivate,
      );

      expect(envelope1.salt, isNot(equals(envelope2.salt)));
      expect(envelope1.nonce, isNot(equals(envelope2.nonce)));
      expect(envelope1.authTag, isNot(equals(envelope2.authTag)));
    });
  });
}
