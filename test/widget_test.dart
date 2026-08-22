import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
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
  testWidgets('brand-new user sees onboarding (not Home)', (tester) async {
    SharedPreferences.setMockInitialValues({});

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
    // Bounded pumps — never pumpAndSettle (can hang on perpetual spinners).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // A completely new user must see onboarding — NOT Home.
    // This is the core regression: authentication status must NOT decide
    // that setup is complete.
    expect(
      find.text('What is your main glow-up goal?'),
      findsOneWidget,
      reason: 'A brand-new user must be shown onboarding.',
    );
    expect(
      find.text('Your Glow Journey'),
      findsNothing,
      reason: 'A brand-new user must NOT be sent straight to Home.',
    );

    await controller.close();
  });

  testWidgets('returning user with onboarding but no intro scan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'glowup_onboarding_completed': true,
      // No 'glowup_intro_flow_completed' → intro flow must appear.
    });

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('AI Face Scan'),
      findsOneWidget,
      reason:
          'A returning user who onboarded but never completed the intro '
          'scan must continue the intro flow, not jump to Home.',
    );
    expect(find.text('Your Glow Journey'), findsNothing);

    await controller.close();
  });

  testWidgets('returning user with full journey sees Home', (tester) async {
    SharedPreferences.setMockInitialValues({
      'glowup_onboarding_completed': true,
      'glowup_intro_flow_completed': true,
    });

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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.text('Your Glow Journey'),
      findsOneWidget,
      reason:
          "A returning user who finished onboarding AND intro flow "
          'must land on Home.',
    );

    await controller.close();
  });
}
