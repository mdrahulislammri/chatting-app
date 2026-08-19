import 'user.dart';
import 'message.dart';

class Conversation {
  final int id;
  final String type;
  final String? name;
  final String? directKey;
  final List<User> members;
  final Message? latestMessage;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.type,
    this.name,
    this.directKey,
    required this.members,
    this.latestMessage,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      type: json['type'],
      name: json['name'],
      directKey: json['direct_key'],
      members: (json['members'] as List<dynamic>?)
              ?.map((m) => User.fromJson(m))
              .toList() ??
          [],
      latestMessage: json['latest_message'] != null
          ? Message.fromJson(json['latest_message'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  String displayName(int currentUserId) {
    if (type == 'group') {
      return name ?? 'Group Chat';
    }
    final other = members.firstWhere(
      (m) => m.id != currentUserId,
      orElse: () => User(id: 0, name: 'Unknown User', email: ''),
    );
    return other.name;
  }
}
