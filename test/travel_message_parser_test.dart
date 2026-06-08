import 'package:decide_ai/core/services/travel_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = TravelMessageParser();

  test(
    'parses natural travel request with plain destination and numeric budget',
    () {
      final result = parser.parse(
        'Spain 1200 beaches and nightlife for a vacation',
      );

      expect(result.destination, contains('Spain'));
      expect(result.budget, contains('1200'));
      expect(result.interests, contains('beaches'));
      expect(result.tripType, 'vacation');
    },
  );

  test('uses the requested field for short follow-up answers', () {
    final budgetResult = parser.parse('1200', expectedField: 'budget');
    final destinationResult = parser.parse(
      'Dubai',
      expectedField: 'destination',
    );

    expect(budgetResult.budget, '1200');
    expect(destinationResult.destination, 'Dubai');
  });
}
