import 'package:flutter/material.dart';

class IdentityChangeBanner extends StatelessWidget {
  final String contactName;
  final VoidCallback onVerifyPressed;

  const IdentityChangeBanner({
    super.key,
    required this.contactName,
    required this.onVerifyPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade700, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security, color: Colors.amber.shade900),
              const SizedBox(width: 8),
              Text(
                'Security Alert',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.amber.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$contactName\'s identity key has changed. '
            'Messaging is suspended until you verify the new identity.',
            style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: onVerifyPressed,
              icon: const Icon(Icons.verified, size: 18),
              label: const Text('Verify Identity'),
            ),
          ),
        ],
      ),
    );
  }
}
