import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../models/message.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/conversation_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isSearching = false;
  List<Message> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(activeChatProvider(widget.conversationId).notifier).sendMessage(text);
      _messageController.clear();
    }
  }

  void _showEditDialog(Message message) {
    final editController = TextEditingController(text: message.content);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Edit message content...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty && message.id != null) {
                ref
                    .read(activeChatProvider(widget.conversationId).notifier)
                    .editMessage(message.id!, newContent);
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_outlined),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(activeChatProvider(widget.conversationId).notifier)
                    .setReplyingTo(message);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                if (message.content != null) {
                  Clipboard.setData(ClipboardData(text: message.content!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied to clipboard')),
                  );
                }
              },
            ),
            if (isMe && !message.isDeleted) ...[
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                title: const Text('Edit Message'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete Message', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  if (message.id != null) {
                    ref
                        .read(activeChatProvider(widget.conversationId).notifier)
                        .deleteMessage(message.id!);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearchLoading = true);
    try {
      final results = await ref
          .read(chatServiceProvider)
          .searchMessages(widget.conversationId, query.trim());
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    } catch (_) {
      setState(() => _isSearchLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(activeChatProvider(widget.conversationId));
    final currentUserId = ref.watch(authProvider).user?.id ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search in conversation...',
                  border: InputBorder.none,
                ),
                onChanged: _performSearch,
              )
            : Text('Chat #${widget.conversationId}'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching && _searchResults.isNotEmpty)
            Container(
              color: Colors.blue.withAlpha(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Found ${_searchResults.length} matching messages',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
            ),
          Expanded(
            child: chatState.isLoading || _isSearchLoading
                ? const Center(child: CircularProgressIndicator())
                : (_isSearching ? _searchResults : chatState.messages).isEmpty
                    ? const Center(
                        child: Text(
                          'No messages found.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        reverse: !_isSearching,
                        padding: const EdgeInsets.all(16),
                        itemCount: _isSearching ? _searchResults.length : chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = _isSearching ? _searchResults[index] : chatState.messages[index];
                          final isMe = msg.senderId == currentUserId;
                          final timeStr = DateFormat('hh:mm a').format(msg.createdAt);

                          return GestureDetector(
                            onLongPress: () => _showMessageOptions(msg, isMe),
                            onSecondaryTap: () => _showMessageOptions(msg, isMe),
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                constraints: const BoxConstraints(maxWidth: 320),
                                decoration: BoxDecoration(
                                  color: msg.isDeleted
                                      ? Colors.grey.shade300
                                      : (isMe ? Colors.blueAccent : Colors.grey.shade200),
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
                                    bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    if (msg.replyTo != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: isMe ? Colors.white24 : Colors.black12,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              msg.replyTo!['sender_name'] ?? 'Reply',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                color: isMe ? Colors.white : Colors.blueAccent,
                                              ),
                                            ),
                                            Text(
                                              msg.replyTo!['content'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isMe ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    Text(
                                      msg.content ?? '',
                                      style: TextStyle(
                                        color: msg.isDeleted
                                            ? Colors.black54
                                            : (isMe ? Colors.white : Colors.black87),
                                        fontSize: 15,
                                        fontStyle: msg.isDeleted ? FontStyle.italic : FontStyle.normal,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (msg.isEdited) ...[
                                          Text(
                                            'edited · ',
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : Colors.black54,
                                              fontSize: 10,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                        Text(
                                          timeStr,
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : Colors.black54,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (isMe && !msg.isDeleted) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            msg.isPending ? Icons.access_time : Icons.done_all,
                                            size: 12,
                                            color: Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (chatState.replyingToMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.withAlpha(20),
              child: Row(
                children: [
                  const Icon(Icons.reply, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${chatState.replyingToMessage!.sender?.name ?? 'Message'}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueAccent),
                        ),
                        Text(
                          chatState.replyingToMessage!.content ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ref
                        .read(activeChatProvider(widget.conversationId).notifier)
                        .clearReply(),
                  ),
                ],
              ),
            ),
          ],
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
