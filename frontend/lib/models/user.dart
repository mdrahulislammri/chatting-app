class User {
  final int id;
  final String name;
  final String email;
  final String? avatarUrl;
  final DateTime? lastSeenAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.lastSeenAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.tryParse(json['last_seen_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar_url': avatarUrl,
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}
