import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/screens/chat_screen.dart';
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
        return Scaffold(
          appBar: AppBar(title: const Text('Contacts & People', style: TextStyle(fontWeight: FontWeight.bold))),
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
        return Scaffold(
          appBar: AppBar(title: const Text('Settings & Security')),
          body: const BackupRecoveryScreen(
            ikSignPrivate: 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
            ikDhPrivate: '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a',
          ),
        );
      case 3:
        return Scaffold(
          appBar: AppBar(title: const Text('My Profile & Active Devices')),
          body: const DeviceSecurityScreen(currentDeviceId: 'desktop-device-001'),
        );
      case 0:
      default:
        return Row(
          children: [
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
            Expanded(
              child: _selectedConversationId != null
                  ? Scaffold(
                      appBar: AppBar(
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Conversation #$_selectedConversationId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: Colors.green),
                                SizedBox(width: 4),
                                Text('Online · E2EE Active 🔒', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                        actions: [
                          IconButton(icon: const Icon(Icons.phone_outlined, color: Colors.blueAccent), onPressed: () {}),
                          IconButton(icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent), onPressed: () {}),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(_showRightPanel ? Icons.info_outline : Icons.info, color: Colors.blueAccent),
                            onPressed: () => setState(() => _showRightPanel = !_showRightPanel),
                          ),
                        ],
                      ),
                      body: ChatScreen(key: ValueKey(_selectedConversationId), conversationId: _selectedConversationId!),
                    )
                  : const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.forum_outlined, size: 72, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Select a conversation to start chatting', style: TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
            ),
            if ((is3Pane || _showRightPanel) && _selectedConversationId != null) ...[
              const VerticalDivider(width: 1, thickness: 1),
              SizedBox(
                width: 300,
                child: Scaffold(
                  appBar: AppBar(title: const Text('Profile Details'), elevation: 0),
                  body: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const CircleAvatar(radius: 36, backgroundColor: Colors.blueAccent, child: Icon(Icons.person, size: 40, color: Colors.white)),
                        const SizedBox(height: 12),
                        Text(user?.name ?? 'Rahul Islam', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 16),
                        ListTile(leading: const Icon(Icons.photo_library_outlined), title: const Text('Shared Media'), onTap: () {}),
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
                NavigationRail(
                  selectedIndex: _selectedNavIndex,
                  onDestinationSelected: (int index) => setState(() => _selectedNavIndex = index),
                  labelType: NavigationRailLabelType.selected,
                  leading: const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Icon(Icons.shield, color: Colors.blueAccent, size: 32)),
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: Text('Chats')),
                    NavigationRailDestination(icon: Icon(Icons.people_alt_outlined), selectedIcon: Icon(Icons.people_alt), label: Text('Contacts')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Profile')),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: () => ref.read(authProvider.notifier).logout()),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: _buildMainView(user, is3Pane)),
              ],
            ),
          );
        } else {
          if (_selectedConversationId != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) { if (!didPop) setState(() => _selectedConversationId = null); },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedConversationId = null)),
                  title: Text('Chat #$_selectedConversationId'),
                ),
                body: ChatScreen(key: ValueKey(_selectedConversationId), conversationId: _selectedConversationId!),
              ),
            );
          }
          return ConversationListScreen(onSelectConversation: (id) => setState(() => _selectedConversationId = id));
        }
      },
    );
  }
}
