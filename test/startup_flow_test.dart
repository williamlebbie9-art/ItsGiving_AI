import 'package:decide_ai/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('new user sees glow-up onboarding then main shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const GivingAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Your AI glow-up era starts here'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Tell us your baseline'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Camera access for selfies'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Allow Camera & Start'));
    await tester.pumpAndSettle();

    expect(find.text('AI Glow Scan'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('Inspo'), findsOneWidget);
  });
}
