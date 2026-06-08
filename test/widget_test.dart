import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:decide_ai/app.dart';

void main() {
  testWidgets('renders redesigned Decide AI home screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DecideAiApp());
    await tester.pumpAndSettle();

    expect(find.text('Decide AI'), findsOneWidget);
    expect(find.text('Make smarter decisions instantly'), findsOneWidget);
    expect(find.text('Choose a category'), findsOneWidget);
    expect(find.text('What should I buy, eat, or choose?'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Smart Suggestions'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Smart Suggestions'), findsOneWidget);
  });
}
