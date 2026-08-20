import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/crypto/encoding/canonical_encoder.dart';
import 'package:frontend/services/backup_service.dart';

void main() {
  group('Cross-Feature Integration & Lifecycle Security Chain Suite', () {
    late BackupService backupService;
    const ikSignPrivateOriginal = 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
    const ikDhPrivateOriginal = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';
    const ikPublicPeer = '9520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6b';

    setUp(() {
      backupService = BackupService();
    });

    test('Chain B & C: Backup Restoration -> Identity Key Recovery -> Safety Number Determinism', () {
      // 1. Generate Mnemonic & Encrypted Backup Envelope
      final mnemonic = backupService.generateMnemonic();
      final envelope = backupService.createEncryptedBackup(
        mnemonic: mnemonic,
        passphrase: 'secure-passphrase-v1',
        ikSignPrivate: ikSignPrivateOriginal,
        ikDhPrivate: ikDhPrivateOriginal,
      );

      // 2. Compute Original Safety Number before loss
      final originalSafetyNumber = CanonicalEncoder.generateSafetyNumber(ikSignPrivateOriginal, ikPublicPeer);

      // 3. Restore Identity Keys from Backup Envelope using Mnemonic
      final restored = backupService.restoreFromBackup(
        mnemonic: mnemonic,
        passphrase: 'secure-passphrase-v1',
        envelope: envelope,
      );

      final restoredSignPrivate = restored['ik_sign_private'] as String;
      final restoredDhPrivate = restored['ik_dh_private'] as String;

      expect(restoredSignPrivate, equals(ikSignPrivateOriginal));
      expect(restoredDhPrivate, equals(ikDhPrivateOriginal));

      // 4. Verify Safety Number matching post-restoration
      final restoredSafetyNumber = CanonicalEncoder.generateSafetyNumber(restoredSignPrivate, ikPublicPeer);
      expect(restoredSafetyNumber, equals(originalSafetyNumber));
    });
  });
}
