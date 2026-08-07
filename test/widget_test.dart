import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:decide_ai/app.dart';

void main() {
  testWidgets('renders its giving.AI glow-up home screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'glowup_onboarding_completed': true,
    });

    await tester.pumpWidget(const GivingAiApp());
    await tester.pumpAndSettle();

    expect(find.text('its giving.AI'), findsOneWidget);
    expect(find.text('AI Glow Scan'), findsOneWidget);
    expect(find.text('Glow'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.text('Diary'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('Inspo'), findsOneWidget);
  });
}
