import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatService {
  final ApiClient apiClient;

  ChatService({required this.apiClient});

  Future<List<User>> fetchUsers({String? search}) async {
    final response = await apiClient.get('/users', queryParameters: search != null && search.isNotEmpty ? {'search': search} : null);
    final List list = response.data['data'];
    return list.map((json) => User.fromJson(json)).toList();
  }

  Future<List<Conversation>> fetchConversations() async {
    final response = await apiClient.get('/conversations');
    final List list = response.data['data'];
    return list.map((json) => Conversation.fromJson(json)).toList();
  }

  Future<Conversation> getOrCreateDirectConversation(int targetUserId) async {
    final response = await apiClient.post('/conversations', data: {
      'type': 'direct',
      'target_user_id': targetUserId,
    });
    return Conversation.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> fetchMessages(int conversationId, {String? beforeCursor}) async {
    final params = <String, dynamic>{'limit': 50};
    if (beforeCursor != null) {
      params['before'] = beforeCursor;
    }

    final response = await apiClient.get('/conversations/$conversationId/messages', queryParameters: params);
    final List list = response.data['data'];
    final messages = list.map((json) => Message.fromJson(json)).toList();
    final meta = response.data['meta'];

    return {
      'messages': messages,
      'next_cursor': meta['next_cursor'],
      'has_more': meta['has_more'],
    };
  }

  Future<Message> sendMessage({
    required int conversationId,
    required String content,
    required String clientMessageId,
    int? replyToId,
    String? type,
    String? attachmentUrl,
    String? attachmentName,
    int? attachmentSize,
    String? mimeType,
  }) async {
    final payload = <String, dynamic>{
      'client_message_id': clientMessageId,
      'content': content,
      'type': type ?? 'text',
    };

    if (attachmentUrl != null) payload['attachment_url'] = attachmentUrl;
    if (attachmentName != null) payload['attachment_name'] = attachmentName;
    if (attachmentSize != null) payload['attachment_size'] = attachmentSize;
    if (mimeType != null) payload['mime_type'] = mimeType;
    if (replyToId != null) payload['reply_to_id'] = replyToId;

    final response = await apiClient.post('/conversations/$conversationId/messages', data: payload);
    return Message.fromJson(response.data['data']);
  }

  Future<Map<String, dynamic>> uploadAttachment({
    required int conversationId,
    required List<int> fileBytes,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName),
    });

    final response = await apiClient.post('/conversations/$conversationId/attachments', data: formData);
    return response.data['data'];
  }

  Future<Message> editMessage(int conversationId, int messageId, String newContent) async {
    final response = await apiClient.post('/conversations/$conversationId/messages/$messageId', data: {
      'content': newContent,
      '_method': 'PATCH',
    });
    return Message.fromJson(response.data['data']);
  }

  Future<void> deleteMessage(int conversationId, int messageId) async {
    await apiClient.post('/conversations/$conversationId/messages/$messageId', data: {
      '_method': 'DELETE',
    });
  }

  Future<List<Message>> searchMessages(int conversationId, String query) async {
    final response = await apiClient.get('/conversations/$conversationId/messages/search', queryParameters: {'q': query});
    final List list = response.data['data'];
    return list.map((json) => Message.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchMedia(int conversationId) async {
    final response = await apiClient.get('/conversations/$conversationId/media');
    final List list = response.data['data'];
    return list.cast<Map<String, dynamic>>();
  }
}
