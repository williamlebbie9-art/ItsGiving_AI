import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:its_giving_ai/app.dart';
import 'package:its_giving_ai/core/providers/app_providers.dart';
import 'package:its_giving_ai/core/services/auth_service.dart';
import 'package:its_giving_ai/features/glowup/glow_up_generator_screen.dart';
import 'package:its_giving_ai/features/glowup/glow_up_plan_screen.dart';
import 'package:its_giving_ai/features/glowup/plan_models.dart';

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

  testWidgets('create new plan opens the generator flow', (tester) async {
    final plan = GlowUpPlan(
      planId: 'plan-1',
      userId: 'user-1',
      createdAt: DateTime.now(),
      overview: 'Test plan',
      weeks: [
        PlanWeek(
          weekNumber: 1,
          title: 'Foundation',
          goal: 'Build consistency',
          focusAreas: const ['Skin', 'Hydration'],
          days: [
            PlanDay(
              dayNumber: 1,
              tasks: const [
                PlanTask(
                  id: 'w1d1t1',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink a glass of water',
                ),
                PlanTask(
                  id: 'w1d1t2',
                  title: 'Morning skincare routine',
                  category: 'Morning',
                  description: 'Cleanse, tone, moisturize, SPF',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    SharedPreferences.setMockInitialValues({
      'glowup_current_plan': plan.toJsonString(),
      'glowup_last_scan_summary': 'Clear skin, balanced hydration.',
      'glowup_last_scan_image_path': '/tmp/fake-image.png',
    });

    await tester.pumpWidget(
      const MaterialApp(home: ProviderScope(child: GlowUpPlanScreen())),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byTooltip('Create New Plan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create New Plan').last);
    await tester.pumpAndSettle();

    expect(find.byType(GlowUpGeneratorScreen), findsOneWidget);
    expect(find.text('Explore Your Glow-Up'), findsOneWidget);
  });

  test('plan streak resets after 24 hours of missed tasks', () {
    final now = DateTime.now();
    final plan = GlowUpPlan(
      planId: 'streak-check',
      userId: 'user-1',
      createdAt: now.subtract(const Duration(days: 2)),
      weeks: [
        PlanWeek(
          weekNumber: 1,
          title: 'Foundation',
          goal: 'Build consistency',
          focusAreas: const ['Skin'],
          days: [
            PlanDay(
              dayNumber: 1,
              tasks: const [
                PlanTask(
                  id: 'd1t1',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                  isCompleted: true,
                  completedAt: null,
                ),
              ],
            ),
            PlanDay(
              dayNumber: 2,
              tasks: const [
                PlanTask(
                  id: 'd2t1',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                  isCompleted: true,
                  completedAt: null,
                ),
              ],
            ),
          ],
        ),
      ],
    );

    final planWithOldCompletion = plan.copyWith(
      weeks: [
        PlanWeek(
          weekNumber: 1,
          title: 'Foundation',
          goal: 'Build consistency',
          focusAreas: const ['Skin'],
          days: [
            PlanDay(
              dayNumber: 1,
              tasks: [
                const PlanTask(
                  id: 'd1t1',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                  isCompleted: true,
                ).copyWith(
                  completedAt: now.subtract(const Duration(hours: 30)),
                ),
              ],
            ),
            PlanDay(
              dayNumber: 2,
              tasks: [
                const PlanTask(
                  id: 'd2t1',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                  isCompleted: true,
                ).copyWith(
                  completedAt: now.subtract(const Duration(hours: 25)),
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(planWithOldCompletion.streak, 0);
  });

  test('consecutive plan days keep a different non-essential task mix', () {
    final plan = GlowUpPlan(
      planId: 'variation-check',
      userId: 'user-1',
      createdAt: DateTime.now(),
      weeks: [
        PlanWeek(
          weekNumber: 1,
          title: 'Foundation',
          goal: 'Build consistency',
          focusAreas: const ['Skin'],
          days: [
            PlanDay(
              dayNumber: 1,
              tasks: const [
                PlanTask(
                  id: 'd1t1',
                  title: 'Morning skincare routine',
                  category: 'Morning',
                  description: 'Cleanse, tone, moisturize, SPF',
                ),
                PlanTask(
                  id: 'd1t2',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                ),
                PlanTask(
                  id: 'd1t3',
                  title: 'Gentle walk',
                  category: 'Fitness',
                  description: 'A simple walk for energy',
                ),
              ],
            ),
            PlanDay(
              dayNumber: 2,
              tasks: const [
                PlanTask(
                  id: 'd2t1',
                  title: 'Morning skincare routine',
                  category: 'Morning',
                  description: 'Cleanse, tone, moisturize, SPF',
                ),
                PlanTask(
                  id: 'd2t2',
                  title: 'Hydration goal',
                  category: 'Lifestyle',
                  description: 'Drink more water',
                ),
                PlanTask(
                  id: 'd2t3',
                  title: 'Gentle walk',
                  category: 'Fitness',
                  description: 'A simple walk for energy',
                ),
              ],
            ),
          ],
        ),
      ],
    );

    expect(plan.hasMeaningfulDayVariation, isFalse);
  });
}
