import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  testWidgets('new user sees onboarding then main shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Fake auth stream — emit null (signed out) so the app routes to onboarding.
    final controller = StreamController<User?>();
    controller.add(null);

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

    expect(find.text('What is your main glow-up goal?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your current skincare routine?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('How often do you exercise?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your typical sleep schedule?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What aesthetic or vibe do you want?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What is your skin type?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('What describes your lifestyle?'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, 'Start My Glow Journey ✨'),
    );
    await tester.pumpAndSettle();

    // Signed-out user completes onboarding → routed to the auth screen.
    expect(find.text('Your glow-up is almost ready ✨'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);

    await controller.close();
  });
}
