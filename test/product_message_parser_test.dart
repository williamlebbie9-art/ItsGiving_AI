import 'package:decide_ai/core/services/product_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = ProductMessageParser();

  test(
    'parses product type, budget, location, and preferences from one message',
    () {
      final result = parser.parse(
        'I need a phone under 300 in Lagos with good battery life',
      );

      expect(result.productName.toLowerCase(), contains('phone'));
      expect(result.budget, contains('300'));
      expect(result.location, contains('Lagos'));
      expect(result.preferences.toLowerCase(), contains('battery'));
    },
  );

  test('extracts compare options from vs-style input', () {
    final result = parser.parse(
      'compare iPhone 13 vs Samsung A54 vs Pixel 8',
      compareMode: true,
    );

    expect(result.compareOptions, hasLength(3));
    expect(result.compareOptions.first, contains('iPhone 13'));
  });
}
