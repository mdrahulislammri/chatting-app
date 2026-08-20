import 'package:flutter/material.dart';
import 'package:frontend/services/backup_service.dart';

class BackupRecoveryScreen extends StatefulWidget {
  final BackupService? backupService;
  final String ikSignPrivate;
  final String ikDhPrivate;

  const BackupRecoveryScreen({
    super.key,
    this.backupService,
    required this.ikSignPrivate,
    required this.ikDhPrivate,
  });

  @override
  State<BackupRecoveryScreen> createState() => _BackupRecoveryScreenState();
}

class _BackupRecoveryScreenState extends State<BackupRecoveryScreen> {
  late final BackupService _backupService;
  String? _mnemonic;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _backupService = widget.backupService ?? BackupService();
  }

  void _generateBackupMnemonic() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Warning'),
        content: const Text(
          'Do NOT take a screenshot of your recovery mnemonic. '
          'Write down these 24 words in exact order on paper and store them in a secure physical location. '
          'Anyone with these 24 words can restore your identity and decrypt your backups.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _mnemonic = _backupService.generateMnemonic();
              });
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadEncryptedBackup() async {
    if (_mnemonic == null) return;
    setState(() => _isExporting = true);

    try {
      final envelope = _backupService.createEncryptedBackup(
        mnemonic: _mnemonic!,
        ikSignPrivate: widget.ikSignPrivate,
        ikDhPrivate: widget.ikDhPrivate,
      );

      final success = await _backupService.uploadBackup(envelope);
      setState(() => _isExporting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Encrypted Backup Uploaded Successfully'
                  : 'Backup Upload Failed. Check API Connection.',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final words = _mnemonic?.split(' ') ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Encrypted Backup & Recovery'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BIP-39 24-Word Mnemonic Recovery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your recovery mnemonic encrypts your private identity keys on your device before uploading to the server.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_mnemonic == null)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                onPressed: _generateBackupMnemonic,
                icon: const Icon(Icons.key),
                label: const Text('Generate 24-Word Recovery Mnemonic'),
              )
            else ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}. ${words[index]}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isExporting ? null : _uploadEncryptedBackup,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: const Text('Encrypt & Upload Backup Envelope'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
