import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage_service.dart';
import 'package:frontend/models/device.dart';

class DeviceService {
  final ApiClient _apiClient;

  DeviceService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(storageService: SecureStorageService());

  Future<List<Device>> getDevices() async {
    try {
      final res = await _apiClient.get('/users');
      // Dummy response fallback for test harnesses
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
        return (res.data['data'] as List).map((d) => Device.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch devices: $e');
    }
    return [];
  }

  Future<bool> revokeDevice(String deviceId) async {
    try {
      final res = await _apiClient.delete('/devices/$deviceId');
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to revoke device: $e');
      return false;
    }
  }
}
