import 'package:flutter/foundation.dart';

@immutable
class BackupEnvelope {
  final int protocolVersion;
  final String kdfVersion;
  final String salt;
  final String nonce;
  final String ciphertext;
  final String authTag;
  final int createdAt;

  const BackupEnvelope({
    this.protocolVersion = 1,
    this.kdfVersion = 'PBKDF2-HMAC-SHA512-HKDF-SHA256-V1',
    required this.salt,
    required this.nonce,
    required this.ciphertext,
    required this.authTag,
    required this.createdAt,
  });

  factory BackupEnvelope.fromJson(Map<String, dynamic> json) {
    if (json['protocol_version'] != 1) {
      throw StateError('Unsupported backup protocol version: ${json['protocol_version']}');
    }
    return BackupEnvelope(
      protocolVersion: json['protocol_version'] as int? ?? 1,
      kdfVersion: json['kdf_version'] as String? ?? 'PBKDF2-HMAC-SHA512-HKDF-SHA256-V1',
      salt: json['salt'] as String,
      nonce: json['nonce'] as String,
      ciphertext: json['ciphertext'] as String,
      authTag: json['auth_tag'] as String,
      createdAt: json['created_at'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'protocol_version': protocolVersion,
      'kdf_version': kdfVersion,
      'salt': salt,
      'nonce': nonce,
      'ciphertext': ciphertext,
      'auth_tag': authTag,
      'created_at': createdAt,
    };
  }
}
