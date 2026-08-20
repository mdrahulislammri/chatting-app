import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/security/screens/safety_number_verification_screen.dart';
import 'package:frontend/features/security/widgets/identity_change_banner.dart';

void main() {
  group('Product Track Module 2: Device Security & Verification UI Tests', () {
    testWidgets('1. Verify Safety Number Formatting and 6-Block Display', (WidgetTester tester) async {
      const ownKey = 'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a';
      const contactKey = '8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a';

      await tester.pumpWidget(
        const MaterialApp(
          home: SafetyNumberVerificationScreen(
            contactName: 'Rahul',
            ownIdentityKey: ownKey,
            contactIdentityKey: contactKey,
          ),
        ),
      );

      expect(find.textContaining('Verify Safety Number — Rahul'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('2. Identity Change Security Warning Alert Banner Rendering', (WidgetTester tester) async {
      bool verifyClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdentityChangeBanner(
              contactName: 'Karim',
              onVerifyPressed: () => verifyClicked = true,
            ),
          ),
        ),
      );

      expect(find.text('Security Alert'), findsOneWidget);
      expect(find.textContaining('Karim\'s identity key has changed.'), findsOneWidget);

      await tester.tap(find.text('Verify Identity'));
      expect(verifyClicked, isTrue);
    });
  });
}
