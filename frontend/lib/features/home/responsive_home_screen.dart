import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chat/screens/chat_screen.dart';
import '../conversations/screens/conversation_list_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final is3Pane = width >= 1440;
        final is2Pane = width >= 1024 && width < 1440;

        if (is3Pane || is2Pane) {
          // Desktop / Web Wide Layout with Far-Left Navigation Rail
          return Scaffold(
            body: Row(
              children: [
                // Zone 0: Far-Left Navigation Sidebar
                NavigationRail(
                  selectedIndex: _selectedNavIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedNavIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.selected,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Icon(Icons.shield, color: Colors.blueAccent, size: 32),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_bubble_outline),
                      selectedIcon: Icon(Icons.chat_bubble, color: Colors.blueAccent),
                      label: Text('Chats'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.people_alt_outlined),
                      selectedIcon: Icon(Icons.people_alt, color: Colors.blueAccent),
                      label: Text('Contacts'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: Colors.blueAccent),
                      label: Text('Settings'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.person_outline),
                      selectedIcon: Icon(Icons.person, color: Colors.blueAccent),
                      label: Text('Profile'),
                    ),
                  ],
                  trailing: Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.redAccent),
                          tooltip: 'Logout',
                          onPressed: () => ref.read(authProvider.notifier).logout(),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),

                // Zone 1: Conversations List Sidebar
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

                // Zone 2: Main Active Chat Window
                Expanded(
                  child: _selectedConversationId != null
                      ? Scaffold(
                          appBar: AppBar(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Rahul Islam #$_selectedConversationId', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                              IconButton(
                                icon: const Icon(Icons.phone_outlined, color: Colors.blueAccent),
                                tooltip: 'Start Voice Call',
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.videocam_outlined, color: Colors.blueAccent),
                                tooltip: 'Start Video Call',
                                onPressed: () {},
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  _showRightPanel ? Icons.info_outline : Icons.info,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Toggle Profile Details',
                                onPressed: () {
                                  setState(() {
                                    _showRightPanel = !_showRightPanel;
                                  });
                                },
                              ),
                            ],
                          ),
                          body: ChatScreen(
                            key: ValueKey(_selectedConversationId),
                            conversationId: _selectedConversationId!,
                          ),
                        )
                      : const Scaffold(
                          body: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.forum_outlined, size: 72, color: Colors.grey),
                                SizedBox(height: 16),
                                Text(
                                  'Select a conversation to start chatting',
                                  style: TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),

                // Zone 3: Right Profile Details Panel
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
                                      'E2E Encrypted Session\nSafety Key: Verified',
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
                              leading: const Icon(Icons.link_outlined),
                              title: const Text('Shared Links'),
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
            ),
          );
        } else {
          // Mobile Single Pane Layout
          if (_selectedConversationId != null) {
            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (!didPop) {
                  setState(() {
                    _selectedConversationId = null;
                  });
                }
              },
              child: Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedConversationId = null;
                      });
                    },
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
            onSelectConversation: (id) {
              setState(() {
                _selectedConversationId = id;
              });
            },
          );
        }
      },
    );
  }
}
