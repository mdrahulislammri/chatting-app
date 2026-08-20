import 'package:flutter/material.dart';
import 'package:frontend/core/crypto/encoding/canonical_encoder.dart';

class SafetyNumberVerificationScreen extends StatefulWidget {
  final String contactName;
  final String ownIdentityKey;
  final String contactIdentityKey;
  final bool isInitiallyVerified;
  final ValueChanged<bool>? onVerificationChanged;

  const SafetyNumberVerificationScreen({
    super.key,
    required this.contactName,
    required this.ownIdentityKey,
    required this.contactIdentityKey,
    this.isInitiallyVerified = false,
    this.onVerificationChanged,
  });

  @override
  State<SafetyNumberVerificationScreen> createState() => _SafetyNumberVerificationScreenState();
}

class _SafetyNumberVerificationScreenState extends State<SafetyNumberVerificationScreen> {
  late String _formattedSafetyNumber;
  late bool _isVerified;

  @override
  void initState() {
    super.initState();
    _isVerified = widget.isInitiallyVerified;
    _formattedSafetyNumber = CanonicalEncoder.generateSafetyNumber(
      widget.ownIdentityKey,
      widget.contactIdentityKey,
    );
  }

  void _toggleVerification(bool value) {
    setState(() => _isVerified = value);
    widget.onVerificationChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Verify Safety Number — ${widget.contactName}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.verified_user, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Compare Safety Number with ${widget.contactName}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'If the safety number matches the number on ${widget.contactName}\'s device, '
              'your end-to-end encrypted session is verified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                _formattedSafetyNumber,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Mark as Verified'),
              subtitle: const Text('Confirm out-of-band safety number verification'),
              value: _isVerified,
              onChanged: _toggleVerification,
            ),
          ],
        ),
      ),
    );
  }
}
