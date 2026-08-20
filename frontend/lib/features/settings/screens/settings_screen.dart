import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../backup/screens/backup_recovery_screen.dart';
import '../../security/screens/device_security_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _selectedCategory = 0;
  String _selectedTheme = 'dark';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Category Navigation Rail
          SizedBox(
            width: 240,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildCategoryTile(0, Icons.person_outline, 'Account'),
                _buildCategoryTile(1, Icons.notifications_none_outlined, 'Notifications'),
                _buildCategoryTile(2, Icons.palette_outlined, 'Appearance'),
                _buildCategoryTile(3, Icons.lock_outline, 'Privacy & Security'),
                _buildCategoryTile(4, Icons.cloud_outlined, 'Encrypted Backup'),
                _buildCategoryTile(5, Icons.devices_outlined, 'Devices & Sessions'),
                _buildCategoryTile(6, Icons.info_outline, 'About E2E'),
              ],
            ),
          ),
          const VerticalDivider(width: 1, thickness: 1),

          // Detail Content View
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: _buildCategoryContent(user),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(int index, IconData icon, String title) {
    final isSelected = _selectedCategory == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blueAccent.withAlpha(25) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blueAccent : null,
          ),
        ),
        onTap: () => setState(() => _selectedCategory = index),
      ),
    );
  }

  Widget _buildCategoryContent(User? user) {
    switch (_selectedCategory) {
      case 0:
        // Account Info
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Display Name'),
              subtitle: Text(user?.name ?? 'Rahul Islam'),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Address'),
              subtitle: Text(user?.email ?? 'rahul@example.com'),
            ),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Username'),
              subtitle: Text('@${user?.email.split('@').first ?? 'rahul_e2e'}'),
            ),
          ],
        );
      case 1:
        // Notifications
        return ListView(
          children: [
            const Text('Notification Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Desktop Notifications'),
              subtitle: const Text('Show notification popups on incoming messages'),
            ),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Sound Alerts'),
              subtitle: const Text('Play sound for incoming messages and calls'),
            ),
            SwitchListTile(
              value: true,
              onChanged: (_) {},
              title: const Text('Show Message Preview'),
              subtitle: const Text('Display sender and message text in notifications'),
            ),
          ],
        );
      case 2:
        // Appearance
        return ListView(
          children: [
            const Text('Appearance & Theme', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.dark_mode, color: _selectedTheme == 'dark' ? Colors.blueAccent : Colors.grey),
              title: const Text('Dark Theme'),
              trailing: _selectedTheme == 'dark' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
              onTap: () => setState(() => _selectedTheme = 'dark'),
            ),
            ListTile(
              leading: Icon(Icons.light_mode, color: _selectedTheme == 'light' ? Colors.blueAccent : Colors.grey),
              title: const Text('Light Theme'),
              trailing: _selectedTheme == 'light' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
              onTap: () => setState(() => _selectedTheme = 'light'),
            ),
            ListTile(
              leading: Icon(Icons.brightness_auto, color: _selectedTheme == 'system' ? Colors.blueAccent : Colors.grey),
              title: const Text('System Default'),
              trailing: _selectedTheme == 'system' ? const Icon(Icons.check, color: Colors.blueAccent) : null,
              onTap: () => setState(() => _selectedTheme = 'system'),
            ),
          ],
        );
      case 3:
        // Privacy & Security
        return ListView(
          children: [
            const Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined, color: Colors.green),
              title: const Text('End-to-End Encryption'),
              subtitle: const Text('Double Ratchet Protocol Active · Verified'),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.blueAccent),
              title: const Text('Identity Keys Management'),
              subtitle: const Text('View and verify active device identity keys'),
            ),
          ],
        );
      case 4:
        // Encrypted Backup
        return const BackupRecoveryScreen(
          ikSignPrivate: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
          ikDhPrivate: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
        );
      case 5:
        // Devices
        return const DeviceSecurityScreen(currentDeviceId: 'desktop-device-001');
      case 6:
      default:
        // About
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('About E2E Chat App', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blueAccent),
              title: const Text('Application Version'),
              subtitle: Text(AppConstants.appVersion),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: Colors.blueAccent),
              title: const Text('Protocol Specification'),
              subtitle: Text(AppConstants.appProtocolVersion),
            ),
          ],
        );
    }
  }
}
