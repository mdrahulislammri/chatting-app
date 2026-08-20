import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/screens/chat_screen.dart';
import '../chat/widgets/empty_chat_widget.dart';
import '../conversations/screens/conversation_list_screen.dart';
import '../security/screens/device_security_screen.dart';
import '../backup/screens/backup_recovery_screen.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';

class ResponsiveHomeScreen extends ConsumerStatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  ConsumerState<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends ConsumerState<ResponsiveHomeScreen> {
  int? _selectedConversationId;
  bool _showRightPanel = true;
  int _selectedNavIndex = 0;

  Widget _buildMainView(User? user, bool is3Pane) {
    switch (_selectedNavIndex) {
      case 1:
        // Contacts View
        return Scaffold(
          appBar: AppBar(
            title: const Text('Contacts & People', style: TextStyle(fontWeight: FontWeight.bold)),
            elevation: 0,
          ),
          body: ConversationListScreen(
            selectedConversationId: _selectedConversationId,
            onSelectConversation: (id) {
              setState(() {
                _selectedConversationId = id;
                _selectedNavIndex = 0;
              });
            },
          ),
        );
      case 2:
        // Settings & Security View
        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Security'),
            elevation: 0,
          ),
          body: const BackupRecoveryScreen(
            ikSignPrivate: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
            ikDhPrivate: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
          ),
        );
      case 3:
        // Profile & Device Sessions
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile & Active Devices'),
            elevation: 0,
          ),
          body: const DeviceSecurityScreen(currentDeviceId: 'desktop-device-001'),
        );
      case 0:
      default:
        // Full 3-Pane Chat Dashboard
        return Row(
          children: [
            // Pane 1: Conversations List
            SizedBox(
              width: 320,
              child: ConversationListScreen(
                selectedConversationId: _selectedConversationId,
                onSelectConversation: (id) {
                  setState(() {
                    _selectedConversationId = id;
                  });
                },
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1),

            // Pane 2: Active Chat Area
            Expanded(
              child: _selectedConversationId != null
                  ? Scaffold(
                      appBar: AppBar(
                        titleSpacing: 16,
                        title: Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                '$_selectedConversationId',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conversation #$_selectedConversationId',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                const Row(
                                  children: [
                                    Icon(Icons.circle, size: 8, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text('Online · E2EE Active 🔒', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(
                            icon: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
                            tooltip: 'Voice Call',
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent),
                            tooltip: 'Video Call',
                            onPressed: () {},
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: Icon(_showRightPanel ? Icons.info : Icons.info_outline, color: Colors.blueAccent),
                            tooltip: 'Toggle Details',
                            onPressed: () => setState(() => _showRightPanel = !_showRightPanel),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      body: ChatScreen(
                        key: ValueKey(_selectedConversationId),
                        conversationId: _selectedConversationId!,
                      ),
                    )
                  : const EmptyChatWidget(),
            ),

            // Pane 3: Profile Details Panel
            if ((is3Pane || _showRightPanel) && _selectedConversationId != null) ...[
              const VerticalDivider(width: 1, thickness: 1),
              SizedBox(
                width: 300,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text('Profile Details'),
                    elevation: 0,
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 36,
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, size: 40, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user?.name ?? 'Rahul Islam',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user?.email.split('@').first ?? 'rahul_e2e'}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withAlpha(50)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.lock_outline, color: Colors.blueAccent, size: 20),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'E2E Encrypted Session\nSafety Key: Verified 🔒',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        ListTile(
                          leading: const Icon(Icons.photo_library_outlined),
                          title: const Text('Shared Media'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: const Text('Files & Documents'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                        ListTile(
                          leading: const Icon(Icons.notifications_none_outlined),
                          title: const Text('Notifications'),
                          trailing: Switch(value: true, onChanged: (_) {}),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final is3Pane = width >= 1440;
        final is2Pane = width >= 1024 && width < 1440;

        if (is3Pane || is2Pane) {
          return Scaffold(
            body: Row(
              children: [
                // Custom Sleek Desktop Sidebar
                _DesktopSidebar(
                  selectedIndex: _selectedNavIndex,
                  onSelect: (index) => setState(() => _selectedNavIndex = index),
                  onLogout: () => ref.read(authProvider.notifier).logout(),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildMainView(user, is3Pane)),
              ],
            ),
          );
        } else {
          // Mobile Single Pane
          if (_selectedConversationId != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) setState(() => _selectedConversationId = null);
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _selectedConversationId = null),
                  ),
                  title: Text('Chat #$_selectedConversationId'),
                ),
                body: ChatScreen(
                  key: ValueKey(_selectedConversationId),
                  conversationId: _selectedConversationId!,
                ),
              ),
            );
          }
          return ConversationListScreen(
            onSelectConversation: (id) => setState(() => _selectedConversationId = id),
          );
        }
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9);

    return Container(
      width: 72,
      color: bgColor,
      child: Column(
        children: [
          const SizedBox(height: 16),
          // App Logo
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blueAccent.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.blueAccent, size: 26),
          ),
          const SizedBox(height: 28),

          // Nav Items
          _NavItem(
            icon: Icons.chat_bubble_outline,
            activeIcon: Icons.chat_bubble,
            label: 'Chats',
            isSelected: selectedIndex == 0,
            onTap: () => onSelect(0),
          ),
          const SizedBox(height: 12),
          _NavItem(
            icon: Icons.people_alt_outlined,
            activeIcon: Icons.people_alt,
            label: 'Contacts',
            isSelected: selectedIndex == 1,
            onTap: () => onSelect(1),
          ),
          const SizedBox(height: 12),
          _NavItem(
            icon: Icons.settings_outlined,
            activeIcon: Icons.settings,
            label: 'Settings',
            isSelected: selectedIndex == 2,
            onTap: () => onSelect(2),
          ),
          const SizedBox(height: 12),
          _NavItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
            label: 'Profile',
            isSelected: selectedIndex == 3,
            onTap: () => onSelect(3),
          ),

          const Spacer(),

          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent, size: 22),
            tooltip: 'Logout',
            onPressed: onLogout,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeBg = isSelected ? Colors.blueAccent : Colors.transparent;
    final iconColor = isSelected ? Colors.white : Colors.grey.shade400;

    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: activeBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Icon(
            isSelected ? activeIcon : icon,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}
