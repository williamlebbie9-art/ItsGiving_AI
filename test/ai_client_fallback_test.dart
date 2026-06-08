import 'package:decide_ai/core/models/decision_models.dart';
import 'package:decide_ai/core/services/ai_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AiClient falls back to mock result when firebase call fails', () async {
    dotenv.testLoad(
      fileInput: '''
AI_PROVIDER=firebase
FIREBASE_FUNCTIONS_URL=http://127.0.0.1:1/generateDecision
''',
    );

    const client = AiClient();
    final result = await client.generate(
      category: DecisionCategory.travel,
      prompt: 'Plan a vacation to Brazil with budget 1500.',
      request: const DecisionRequest(
        query: 'Plan a vacation to Brazil with budget 1500.',
        manualCategory: DecisionCategory.travel,
        budget: '1500',
        location: 'Brazil',
        preferences: 'beaches food and adventure',
        occasion: 'vacation',
      ),
    );

    expect(result.bestChoice, isNotEmpty);
    expect(result.reasoning, isNotEmpty);
    expect(result.category, DecisionCategory.travel);
  });
}
