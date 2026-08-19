import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/secure_storage_service.dart';

class RealtimeService {
  final SecureStorageService storageService;
  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();
  bool _isInitialized = false;

  RealtimeService({required this.storageService});

  Future<void> init(Function(dynamic event) onEvent) async {
    if (_isInitialized) return;

    final token = await storageService.getToken();

    try {
      await pusher.init(
        apiKey: ApiConstants.reverbAppKey,
        cluster: 'mt1',
        useTLS: false,
        authEndpoint: '${ApiConstants.baseUrl}/broadcasting/auth',
        onEvent: onEvent,
        onAuthorizer: (channelName, socketId, options) async {
          return {
            'auth': 'bearer:$token',
          };
        },
      );

      await pusher.connect();
      _isInitialized = true;
    } catch (_) {
      // Graceful fallback for offline / disconnected state
    }
  }

  Future<void> subscribeToConversation(int conversationId) async {
    try {
      await pusher.subscribe(channelName: 'private-conversation.$conversationId');
    } catch (_) {}
  }

  Future<void> unsubscribeFromConversation(int conversationId) async {
    try {
      await pusher.unsubscribe(channelName: 'private-conversation.$conversationId');
    } catch (_) {}
  }

  Future<void> disconnect() async {
    try {
      await pusher.disconnect();
      _isInitialized = false;
    } catch (_) {}
  }
}
