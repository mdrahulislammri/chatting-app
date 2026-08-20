import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.person, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'Rahul Islam',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '@${user?.email.split('@').first ?? 'rahul_e2e'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'rahul@example.com'),
                ),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Colors.blueAccent),
                  title: const Text('Account Security'),
                  subtitle: const Text('E2E Double Ratchet Encryption Active'),
                ),
                ListTile(
                  leading: const Icon(Icons.devices_outlined),
                  title: const Text('Active Sessions'),
                  subtitle: const Text('Windows PC (Current Device)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
