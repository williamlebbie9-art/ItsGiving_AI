import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decide_ai/app.dart';
import 'package:decide_ai/core/providers/app_providers.dart';
import 'package:decide_ai/core/services/auth_service.dart';

/// Minimal fake User for tests — avoids touching native Firebase.
class TestUser implements User {
  const TestUser();

  @override
  String get uid => 'test-uid-123';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('App renders signed-in home shell', (tester) async {
    SharedPreferences.setMockInitialValues({
      'glowup_onboarding_completed': true,
    });

    // Fake auth stream that immediately emits a signed-in user.
    final controller = StreamController<User?>();
    controller.add(const TestUser());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(
            AuthService(authStateStream: controller.stream),
          ),
        ],
        child: const GivingAiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Glow Journey'), findsOneWidget);

    await controller.close();
  });
}
