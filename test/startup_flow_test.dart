import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:its_giving_ai/app.dart';
import 'package:its_giving_ai/core/providers/app_providers.dart';
import 'package:its_giving_ai/core/services/auth_service.dart';

/// Minimal fake User for tests — avoids touching native Firebase.
class TestUser implements User {
  const TestUser();

  @override
  String get uid => 'test-uid-123';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('new user sees onboarding then intro face scan', (tester) async {
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
    // Use bounded pumps (never pumpAndSettle) so tests cannot hang on
    // perpetual animations (e.g. spinners).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Brand-new user → onboarding appears.
    expect(
      find.text('What is your main glow-up goal?'),
      findsOneWidget,
      reason: 'A brand-new user must see onboarding, not Home.',
    );
    expect(find.text('Your Glow Journey'), findsNothing);

    // Walk through the remaining 6 onboarding questions.
    for (var page = 0; page < 6; page++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    // Final question — tap Start.
    await tester.tap(
      find.widgetWithText(FilledButton, 'Start My Glow Journey ✨'),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // 2. After onboarding → intro face scan flow appears, NOT Home.
    expect(
      find.text('AI Face Scan'),
      findsOneWidget,
      reason: 'After onboarding the user must continue to the intro scan.',
    );
    expect(
      find.text('Your Glow Journey'),
      findsNothing,
      reason: 'The user must NOT be routed to Home after onboarding.',
    );
    expect(
      find.text('Your glow-up is almost ready ✨'),
      findsNothing,
      reason: 'The auth screen must not block the intro flow for new users.',
    );

    await controller.close();
  });
}
