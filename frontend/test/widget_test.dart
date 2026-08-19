import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage_service.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/services/auth_service.dart';

class MockAuthService implements AuthService {
  @override
  late final ApiClient apiClient;

  @override
  late final SecureStorageService storageService;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> login(String email, String password) async => User(id: 1, name: 'Test', email: email);

  @override
  Future<User> register(String name, String email, String password) async => User(id: 1, name: name, email: email);

  @override
  Future<void> logout() async {}
}

void main() {
  testWidgets('App renders successfully test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
        child: const E2EApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(E2EApp), findsOneWidget);
  });
}
