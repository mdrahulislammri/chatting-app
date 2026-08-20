import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

final secureStorageProvider = Provider((ref) => SecureStorageService());

final apiClientProvider = Provider((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storageService: storage);
});

final authServiceProvider = Provider((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthService(apiClient: api, storageService: storage);
});

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState(isLoading: true)) {
    checkCurrentUser();
  }

  Future<void> checkCurrentUser() async {
    try {
      final user = await _authService.getCurrentUser();
      state = AuthState(user: user, isLoading: false);
    } catch (_) {
      state = AuthState(user: null, isLoading: false);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.login(email, password);
      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseErrorMessage(e));
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _authService.register(name, email, password);
      state = AuthState(user: user, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _parseErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _authService.logout();
    state = AuthState(user: null, isLoading: false);
  }

  static String _parseErrorMessage(dynamic e) {
    if (e is DioException) {
      final responseData = e.response?.data;
      if (responseData is Map) {
        if (responseData['message'] != null && responseData['message'].toString().isNotEmpty) {
          return responseData['message'].toString();
        }
        if (responseData['errors'] is Map) {
          final errors = responseData['errors'] as Map;
          if (errors.isNotEmpty) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
          }
        }
      }
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.connectionError) {
        return 'Server connection failed. Please check if backend server is running.';
      }
      if (e.response?.statusCode == 422) {
        return 'Invalid email or password. Please check your credentials.';
      }
    }
    return e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
