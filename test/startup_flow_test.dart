import 'package:decide_ai/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('new user sees enhanced glow-up onboarding then main shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GivingAiApp());
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

    expect(find.text('Your Glow Journey'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('Inspo'), findsOneWidget);
  });
}
