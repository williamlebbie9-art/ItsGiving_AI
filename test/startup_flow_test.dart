import 'package:decide_ai/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('new user sees onboarding then sign in then paywall', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const DecideAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Make Smarter Choices'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Continue').first);
    await tester.pumpAndSettle();

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Next').first);
      await tester.pumpAndSettle();
    }

    final startFreeButton = find
        .descendant(
          of: find.byType(ElevatedButton),
          matching: find.text('Start Free'),
        )
        .first;

    expect(startFreeButton, findsOneWidget);
    await tester.tap(startFreeButton);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to Continue'), findsOneWidget);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Compare anything. Decide smarter.'), findsOneWidget);
    expect(
      find.text('Start your 14-day free trial on all paid plans'),
      findsOneWidget,
    );
    expect(find.text('PROMAX'), findsWidgets);
    expect(find.text('\$34.99'), findsOneWidget);
  });
}
