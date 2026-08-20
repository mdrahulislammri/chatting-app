import 'package:flutter/foundation.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage_service.dart';
import 'package:frontend/models/call_state.dart';

class WebRtcCallService {
  final ApiClient _apiClient;

  WebRtcCallService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient(storageService: SecureStorageService());

  static const Map<CallState, Set<CallState>> _allowedTransitions = {
    CallState.initiating: {CallState.ringing, CallState.ended, CallState.failed},
    CallState.ringing: {CallState.connecting, CallState.ended, CallState.failed},
    CallState.connecting: {CallState.connected, CallState.ended, CallState.failed},
    CallState.connected: {CallState.ended, CallState.failed},
    CallState.ended: {},
    CallState.failed: {},
  };

  CallState validateAndTransition(CallState current, CallState next) {
    if (current == next) return current;

    final allowed = _allowedTransitions[current] ?? {};
    if (!allowed.contains(next)) {
      throw StateError('Invalid call state transition from [$current] to [$next]');
    }

    return next;
  }

  Future<Map<String, dynamic>?> initiateCall({
    required String conversationId,
    required String callerDeviceId,
    String type = 'audio',
  }) async {
    try {
      final res = await _apiClient.post(
        '/conversations/$conversationId/call/initiate',
        data: {
          'caller_device_id': callerDeviceId,
          'type': type,
        },
      );
      if (res.statusCode == 201 && res.data is Map && res.data['data'] is Map) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to initiate call: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> sendSignal({
    required String conversationId,
    required String callId,
    required String senderDeviceId,
    required String type,
    Map<String, dynamic>? payload,
  }) async {
    try {
      final res = await _apiClient.post(
        '/conversations/$conversationId/call/$callId/signal',
        data: {
          'sender_device_id': senderDeviceId,
          'type': type,
          'payload': payload ?? {},
          'timestamp_ms': DateTime.now().millisecondsSinceEpoch,
        },
      );
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to send call signal: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> getTurnCredentials() async {
    try {
      final res = await _apiClient.get('/call/turn-credentials');
      if (res.statusCode == 200 && res.data is Map && res.data['data'] is Map) {
        return res.data['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Failed to fetch TURN credentials: $e');
    }
    return null;
  }
}
