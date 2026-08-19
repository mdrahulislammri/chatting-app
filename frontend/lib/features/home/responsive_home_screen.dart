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

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final is3Pane = width >= 1440;
        final is2Pane = width >= 1024 && width < 1440;

        if (is3Pane || is2Pane) {
          // Desktop / Web Wide Layout (2-Pane or 3-Pane)
          return Scaffold(
            body: Row(
              children: [
                // Zone 1: Conversations Sidebar
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

                // Zone 2: Main Active Chat Area
                Expanded(
                  child: _selectedConversationId != null
                      ? Scaffold(
                          appBar: AppBar(
                            title: Text('Conversation #$_selectedConversationId'),
                            actions: [
                              IconButton(
                                icon: Icon(
                                  _showRightPanel
                                      ? Icons.info_outline
                                      : Icons.info,
                                  color: Colors.blueAccent,
                                ),
                                tooltip: 'Toggle Details Panel',
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

                // Zone 3: Right Details Panel (Active on >=1440px or if toggled)
                if ((is3Pane || _showRightPanel) && _selectedConversationId != null) ...[
                  const VerticalDivider(width: 1, thickness: 1),
                  SizedBox(
                    width: 300,
                    child: Scaffold(
                      appBar: AppBar(
                        title: const Text('Details'),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.circle, size: 8, color: Colors.green),
                                SizedBox(width: 6),
                                Text('Online', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),
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
            ),
          );
        } else {
          // Mobile / Tablet Single Pane Layout (<1024px)
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
