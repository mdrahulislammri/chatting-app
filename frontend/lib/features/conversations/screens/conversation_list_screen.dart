import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conversation_provider.dart';
import '../../chats/dialogs/new_chat_dialog.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  final Function(int conversationId)? onSelectConversation;
  final int? selectedConversationId;

  const ConversationListScreen({
    super.key,
    this.onSelectConversation,
    this.selectedConversationId,
  });

  @override
  ConsumerState<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNewChatDialog() {
    showDialog(
      context: context,
      builder: (context) => NewChatDialog(
        onSelectConversation: (id) {
          if (widget.onSelectConversation != null) {
            widget.onSelectConversation!(id);
          }
        },
      ),
    );
  }

  void _startChatWithUser(User user) async {
    final conversation = await ref
        .read(conversationListProvider.notifier)
        .getOrCreateDirectConversation(user.id);

    if (conversation != null && widget.onSelectConversation != null) {
      widget.onSelectConversation!(conversation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final convState = ref.watch(conversationListProvider);
    final currentUserId = authState.user?.id ?? 0;
    final usersAsync = ref.watch(userListProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note, color: Colors.blueAccent),
            tooltip: 'New Conversation',
            onPressed: _openNewChatDialog,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search users to chat...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) {
                setState(() => _searchQuery = v.trim());
              },
            ),
          ),
          Expanded(
            child: _searchQuery.isNotEmpty
                ? usersAsync.when(
                    data: (users) {
                      if (users.isEmpty) {
                        return const Center(child: Text('No users found.'));
                      }
                      return ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final u = users[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(u.name[0].toUpperCase()),
                            ),
                            title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(u.email),
                            onTap: () => _startChatWithUser(u),
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(child: Text('Error: $err')),
                  )
                : convState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : convState.conversations.isEmpty
                        ? const Center(
                            child: Text(
                              'No conversations yet.\nSearch users above to start chatting!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => ref
                                .read(conversationListProvider.notifier)
                                .loadConversations(),
                            child: ListView.builder(
                              itemCount: convState.conversations.length,
                              itemBuilder: (context, index) {
                                final conv = convState.conversations[index];
                                final isSelected = conv.id == widget.selectedConversationId;

                                return Container(
                                  color: isSelected ? Colors.blue.withAlpha(25) : null,
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blueAccent,
                                      child: Text(
                                        conv.displayName(currentUserId)[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    title: Text(
                                      conv.displayName(currentUserId),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      conv.latestMessage?.content ?? 'No messages yet',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onTap: () {
                                      if (widget.onSelectConversation != null) {
                                        widget.onSelectConversation!(conv.id);
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
