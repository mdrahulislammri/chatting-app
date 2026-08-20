class Device {
  final String id;
  final String userId;
  final String name;
  final String publicIdentityKey;
  final bool isActive;
  final String? pushToken;
  final String platform;

  Device({
    required this.id,
    required this.userId,
    required this.name,
    required this.publicIdentityKey,
    required this.isActive,
    this.pushToken,
    this.platform = 'android',
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: (json['id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      publicIdentityKey: (json['public_identity_key'] ?? '').toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      pushToken: json['push_token']?.toString(),
      platform: (json['platform'] ?? 'android').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'public_identity_key': publicIdentityKey,
      'is_active': isActive,
      'push_token': pushToken,
      'platform': platform,
    };
  }
}
