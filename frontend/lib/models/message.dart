import 'user.dart';

class Message {
  final int? id;
  final int conversationId;
  final int senderId;
  final User? sender;
  final String? content;
  final String type;
  final String? attachmentUrl;
  final String? attachmentName;
  final int? attachmentSize;
  final String? mimeType;
  final String? thumbnailUrl;
  final int? replyToId;
  final Map<String, dynamic>? replyTo;
  final String clientMessageId;
  final bool isDeleted;
  final bool isEdited;
  final DateTime createdAt;
  final bool isPending;

  Message({
    this.id,
    required this.conversationId,
    required this.senderId,
    this.sender,
    this.content,
    this.type = 'text',
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentSize,
    this.mimeType,
    this.thumbnailUrl,
    this.replyToId,
    this.replyTo,
    required this.clientMessageId,
    this.isDeleted = false,
    this.isEdited = false,
    required this.createdAt,
    this.isPending = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      conversationId: json['conversation_id'],
      senderId: json['sender_id'] ?? (json['sender'] != null ? json['sender']['id'] : 0),
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'],
      type: json['type'] ?? 'text',
      attachmentUrl: json['attachment_url'],
      attachmentName: json['attachment_name'],
      attachmentSize: json['attachment_size'],
      mimeType: json['mime_type'],
      thumbnailUrl: json['thumbnail_url'],
      replyToId: json['reply_to_id'],
      replyTo: json['reply_to'] != null ? Map<String, dynamic>.from(json['reply_to']) : null,
      clientMessageId: json['client_message_id'] ?? '',
      isDeleted: json['is_deleted'] ?? false,
      isEdited: json['is_edited'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isPending: false,
    );
  }

  Message copyWith({
    int? id,
    String? content,
    bool? isDeleted,
    bool? isEdited,
    bool? isPending,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId,
      senderId: senderId,
      sender: sender,
      content: content ?? this.content,
      type: type,
      attachmentUrl: attachmentUrl,
      attachmentName: attachmentName,
      attachmentSize: attachmentSize,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
      replyToId: replyToId,
      replyTo: replyTo,
      clientMessageId: clientMessageId,
      isDeleted: isDeleted ?? this.isDeleted,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt,
      isPending: isPending ?? this.isPending,
    );
  }
}
