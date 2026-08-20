import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user.dart';
import '../../../providers/conversation_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  final Function(int conversationId) onSelectConversation;

  const ContactsScreen({
    super.key,
    required this.onSelectConversation,
  });

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startChatWithUser(User user) async {
    final conversation = await ref
        .read(conversationListProvider.notifier)
        .getOrCreateDirectConversation(user.id);

    if (conversation != null) {
      widget.onSelectConversation(conversation.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(userListProvider(_searchQuery));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts & People', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blueAccent,
          labelColor: Colors.blueAccent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All Contacts'),
            Tab(text: 'Online'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts by name or email...',
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
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(usersAsync, (u) => true),
                _buildUserList(usersAsync, (u) => u.id % 2 == 1),
                _buildUserList(usersAsync, (u) => false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(AsyncValue<List<User>> usersAsync, bool Function(User) filter) {
    return usersAsync.when(
      data: (users) {
        final filtered = users.where(filter).toList();
        if (filtered.isEmpty) {
          return const Center(
            child: Text('No contacts found.', style: TextStyle(color: Colors.grey)),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: filtered.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final u = filtered[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              leading: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  u.name[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${u.email.split('@').first} · ${u.email}', style: const TextStyle(fontSize: 12)),
              trailing: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _startChatWithUser(u),
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: const Text('Message'),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}
