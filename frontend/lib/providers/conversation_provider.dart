import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/conversation.dart';
import '../models/user.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);
  return ChatService(apiClient: api);
});

class ConversationListState {
  final List<Conversation> conversations;
  final bool isLoading;
  final String? error;

  ConversationListState({
    this.conversations = const [],
    this.isLoading = false,
    this.error,
  });

  ConversationListState copyWith({
    List<Conversation>? conversations,
    bool? isLoading,
    String? error,
  }) {
    return ConversationListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ConversationListNotifier extends StateNotifier<ConversationListState> {
  final ChatService _chatService;

  ConversationListNotifier(this._chatService) : super(ConversationListState(isLoading: true)) {
    loadConversations();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final conversations = await _chatService.fetchConversations();
      state = ConversationListState(conversations: conversations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<Conversation?> getOrCreateDirectConversation(int targetUserId) async {
    try {
      final conversation = await _chatService.getOrCreateDirectConversation(targetUserId);
      await loadConversations();
      return conversation;
    } catch (e) {
      return null;
    }
  }
}

final conversationListProvider = StateNotifierProvider<ConversationListNotifier, ConversationListState>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ConversationListNotifier(chatService);
});

final userListProvider = FutureProvider.family<List<User>, String?>((ref, search) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.fetchUsers(search: search);
});
