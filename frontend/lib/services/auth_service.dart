import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient apiClient;
  final SecureStorageService storageService;

  AuthService({required this.apiClient, required this.storageService});

  Future<User> register(String name, String email, String password) async {
    final response = await apiClient.post('/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });

    final token = response.data['data']['token'];
    await storageService.saveToken(token);
    return User.fromJson(response.data['data']['user']);
  }

  Future<User> login(String email, String password) async {
    final response = await apiClient.post('/auth/login', data: {
      'email': email,
      'password': password,
    });

    final token = response.data['data']['token'];
    await storageService.saveToken(token);
    return User.fromJson(response.data['data']['user']);
  }

  Future<User?> getCurrentUser() async {
    final token = await storageService.getToken();
    if (token == null || token.isEmpty) return null;

    try {
      final response = await apiClient.get('/auth/me');
      return User.fromJson(response.data['data']);
    } catch (_) {
      await storageService.deleteToken();
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/auth/logout');
    } catch (_) {}
    await storageService.deleteToken();
  }
}
