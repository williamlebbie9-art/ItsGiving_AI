import 'package:decide_ai/core/models/decision_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'DecisionResult parses backend JSON with camelCase keys and object values',
    () {
      final result = DecisionResult.fromJson({
        'bestChoice': {'destination': 'Barcelona', 'budget': 1200},
        'alternatives': [
          {'destination': 'Valencia'},
          {'destination': 'Malaga'},
        ],
        'reasoning': 'Barcelona fits the requested budget and vibe.',
        'pros': ['Great beaches', 'Good nightlife'],
        'cons': ['Crowded in peak season'],
        'confidenceScore': 0.91,
        'category': 'travel',
      });

      expect(result.bestChoice, contains('Barcelona'));
      expect(result.alternatives, isNotEmpty);
      expect(result.alternatives.first, contains('Valencia'));
      expect(result.confidenceScore, '0.91');
      expect(result.category, DecisionCategory.travel);
    },
  );
}
