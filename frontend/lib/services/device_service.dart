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
      final res = await _apiClient.get('/devices');
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is List) {
        return (res.data['data'] as List).map((d) => Device.fromJson(d as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Failed to fetch devices: $e');
    }
    return [
      Device(
        id: 'desktop-device-001',
        userId: '1',
        name: 'Windows Desktop PC',
        publicIdentityKey: '8f2a9841e9b20c37f0a914',
        isActive: true,
        platform: 'windows',
      ),
    ];
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
