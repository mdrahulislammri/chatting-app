import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../services/realtime_service.dart';
import 'auth_provider.dart';
import 'conversation_provider.dart';

final realtimeServiceProvider = Provider((ref) {
  final storage = ref.watch(secureStorageProvider);
  return RealtimeService(storageService: storage);
});

class ChatState {
  final List<Message> messages;
  final bool isLoading;
  final String? nextCursor;
  final bool hasMore;
  final String? error;
  final Message? replyingToMessage;

  ChatState({
    this.messages = const [],
    this.isLoading = false,
    this.nextCursor,
    this.hasMore = false,
    this.error,
    this.replyingToMessage,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? nextCursor,
    bool? hasMore,
    String? error,
    Message? replyingToMessage,
    bool clearReply = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      replyingToMessage: clearReply ? null : (replyingToMessage ?? this.replyingToMessage),
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final int conversationId;
  final ChatService _chatService;
  final RealtimeService _realtimeService;
  final int currentUserId;
  final _uuid = const Uuid();

  ChatNotifier({
    required this.conversationId,
    required ChatService chatService,
    required RealtimeService realtimeService,
    required this.currentUserId,
  })  : _chatService = chatService,
        _realtimeService = realtimeService,
        super(ChatState(isLoading: true)) {
    initChat();
  }

  Future<void> initChat() async {
    await fetchMessages();
    await _realtimeService.init((event) {
      if (event.eventName == 'message.sent' || event.eventName == 'MessageSent') {
        if (event.data != null) {
          final incoming = Message.fromJson(event.data);
          if (incoming.conversationId == conversationId) {
            receiveMessage(incoming);
          }
        }
      } else if (event.eventName == 'message.updated' || event.eventName == 'MessageUpdated') {
        if (event.data != null) {
          final updated = Message.fromJson(event.data);
          if (updated.conversationId == conversationId) {
            receiveUpdatedMessage(updated);
          }
        }
      } else if (event.eventName == 'message.deleted' || event.eventName == 'MessageDeleted') {
        if (event.data != null) {
          final int msgId = event.data['messageId'] ?? 0;
          if (msgId > 0) {
            receiveDeletedMessage(msgId);
          }
        }
      }
    });
    await _realtimeService.subscribeToConversation(conversationId);
  }

  Future<void> fetchMessages({bool loadMore = false}) async {
    if (loadMore && (!state.hasMore || state.isLoading)) return;

    if (!loadMore) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final res = await _chatService.fetchMessages(
        conversationId,
        beforeCursor: loadMore ? state.nextCursor : null,
      );

      final List<Message> fetched = res['messages'];
      final String? nextCursor = res['next_cursor'];
      final bool hasMore = res['has_more'];

      if (loadMore) {
        state = state.copyWith(
          messages: [...state.messages, ...fetched],
          nextCursor: nextCursor,
          hasMore: hasMore,
          isLoading: false,
        );
      } else {
        state = ChatState(
          messages: fetched,
          nextCursor: nextCursor,
          hasMore: hasMore,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setReplyingTo(Message? message) {
    state = state.copyWith(replyingToMessage: message);
  }

  void clearReply() {
    state = state.copyWith(clearReply: true);
  }

  void receiveMessage(Message message) {
    final exists = state.messages.any((m) =>
        (m.id != null && m.id == message.id) ||
        (m.clientMessageId == message.clientMessageId));

    if (exists) {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.clientMessageId == message.clientMessageId) {
            return message;
          }
          return m;
        }).toList(),
      );
    } else {
      state = state.copyWith(
        messages: [message, ...state.messages],
      );
    }
  }

  void receiveUpdatedMessage(Message message) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == message.id) {
          return message;
        }
        return m;
      }).toList(),
    );
  }

  void receiveDeletedMessage(int messageId) {
    state = state.copyWith(
      messages: state.messages.map((m) {
        if (m.id == messageId) {
          return m.copyWith(content: 'This message was deleted', isDeleted: true);
        }
        return m;
      }).toList(),
    );
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final clientMsgId = _uuid.v4();
    final replyToMsg = state.replyingToMessage;

    final optimisticMessage = Message(
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      clientMessageId: clientMsgId,
      replyToId: replyToMsg?.id,
      replyTo: replyToMsg != null
          ? {
              'id': replyToMsg.id,
              'content': replyToMsg.content,
              'sender_name': replyToMsg.sender?.name ?? 'User',
            }
          : null,
      createdAt: DateTime.now(),
      isPending: true,
    );

    state = state.copyWith(
      messages: [optimisticMessage, ...state.messages],
      clearReply: true,
    );

    try {
      final confirmedMessage = await _chatService.sendMessage(
        conversationId: conversationId,
        content: content,
        clientMessageId: clientMsgId,
        replyToId: replyToMsg?.id,
      );

      receiveMessage(confirmedMessage);
    } catch (e) {
      state = state.copyWith(
        messages: state.messages.where((m) => m.clientMessageId != clientMsgId).toList(),
      );
    }
  }

  Future<void> editMessage(int messageId, String newContent) async {
    try {
      final updated = await _chatService.editMessage(conversationId, messageId, newContent);
      receiveUpdatedMessage(updated);
    } catch (_) {}
  }

  Future<void> deleteMessage(int messageId) async {
    try {
      await _chatService.deleteMessage(conversationId, messageId);
      receiveDeletedMessage(messageId);
    } catch (_) {}
  }

  @override
  void dispose() {
    _realtimeService.unsubscribeFromConversation(conversationId);
    super.dispose();
  }
}

final activeChatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, int>((ref, conversationId) {
  final chatService = ref.watch(chatServiceProvider);
  final realtimeService = ref.watch(realtimeServiceProvider);
  final authState = ref.watch(authProvider);

  return ChatNotifier(
    conversationId: conversationId,
    chatService: chatService,
    realtimeService: realtimeService,
    currentUserId: authState.user?.id ?? 0,
  );
});
