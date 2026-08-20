import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage_service.dart';

class PushNotificationService {
  final ApiClient _apiClient;

  PushNotificationService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(storageService: SecureStorageService());

  Future<bool> registerDevicePushToken({
    required String deviceId,
    required String pushToken,
    String platform = 'android',
  }) async {
    try {
      final res = await _apiClient.post(
        '/devices/$deviceId/push-token',
        data: {
          'push_token': pushToken,
          'platform': platform,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to register push token: $e');
      return false;
    }
  }

  Future<bool> revokeDevicePushToken({required String deviceId}) async {
    try {
      final res = await _apiClient.delete('/devices/$deviceId/push-token');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to revoke push token: $e');
      return false;
    }
  }

  Map<String, dynamic>? parseUltraPrivatePayload(String payloadJson) {
    try {
      final data = jsonDecode(payloadJson) as Map<String, dynamic>;
      if (data['type'] == 'new_message' && data.containsKey('notification_id')) {
        return data;
      }
    } catch (e) {
      debugPrint('Failed to parse push notification payload: $e');
    }
    return null;
  }
}
