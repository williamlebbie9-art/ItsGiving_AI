import '../models/decision_models.dart';

class DecisionPrompts {
  const DecisionPrompts();

  String build({
    required DecisionCategory category,
    required DecisionRequest request,
  }) {
    final compareBlock = request.compareOptions.isEmpty
        ? ''
        : 'Compare options: ${request.compareOptions.join(' | ')}.';

    final compareInstruction = request.compareOptions.isEmpty
        ? ''
        : '''
  When compare options are provided:
  - Mention each provided option by name.
  - Compare their strengths and weaknesses directly.
  - Explain why the chosen winner is better for this user's budget and preferences.
  - Use alternatives array to include runner-up options in ranked order.
  ''';

    // Build personalization context from user profile
    final personalizationContext = _buildPersonalizationContext(request);

    final context = [
      if ((request.budget ?? '').trim().isNotEmpty) 'Budget: ${request.budget}',
      if ((request.location ?? '').trim().isNotEmpty)
        'Location: ${request.location}',
      if ((request.preferences ?? '').trim().isNotEmpty)
        'Preferences: ${request.preferences}',
      if ((request.weather ?? '').trim().isNotEmpty)
        'Weather: ${request.weather}',
      if ((request.occasion ?? '').trim().isNotEmpty)
        'Occasion: ${request.occasion}',
      if ((request.userStyle ?? '').trim().isNotEmpty)
        'Style: ${request.userStyle}',
      if (request.imagePaths.isNotEmpty)
        'Image count: ${request.imagePaths.length}',
      if (personalizationContext.isNotEmpty)
        'User Profile: $personalizationContext',
      compareBlock,
    ].where((entry) => entry.isNotEmpty).join(' ');

    final system = switch (category) {
      DecisionCategory.food =>
        '''
Act as a local food expert.
Primary objective: recommend the best dining option for budget, location, occasion, and vibe.
Food scoring criteria:
- Budget fit (high priority)
- Distance/convenience (high priority)
- Occasion fit and vibe (high priority)
- Cuisine preference match
- Wait-time and reservation practicality
Include vibe tags when useful: romantic, casual, luxury, family-friendly, quick bite.
''',
      DecisionCategory.travel =>
        '''
Act as a travel planner.
Primary objective: suggest destinations that maximize value for budget, duration, and travel style.
Travel scoring criteria:
- Budget realism (flight + stay + food + transport)
- Time efficiency for trip length
- Seasonal timing (best time to visit)
- Experience fit (relax, adventure, culture, nightlife)
- Safety and logistics simplicity
When relevant, include rough cost breakdown: transport, lodging, food, activities.
''',
      DecisionCategory.products =>
        '''
Act as a product buying advisor.
Recommend the best item by budget, durability, and 2-3 year value.
If comparing options, prioritize reliability, warranty, maintenance cost, performance per dollar, and availability.
Always include an estimated current price range and 1-3 supplier/store suggestions (online or local) in the response.
Use the pros array for compact shopping notes such as:
- Estimated price: ...
- Where to buy: ...
- Best for: ...
''',
      DecisionCategory.fashion =>
        '''
Act as a fashion stylist.
Recommend outfits using weather, occasion, and user style.
If comparing outfits, evaluate fit, proportion, color harmony, and context suitability.
Provide one practical style improvement tip.
''',
    };

    if (request.plainResponse) {
      return '''
You are DecideAI.
$system

User question: ${request.query}
Context: $context
$compareInstruction

Answer the user's question directly in 1-2 concise sentences focused on the question. If you need more information to answer, ask a single clarifying question. Do not return JSON — respond in plain text only.
''';
    }

    return '''
You are DecideAI.
$system

User question: ${request.query}
Context: $context
$compareInstruction

Return strict JSON only with this exact shape:
{
  "best_choice": "",
  "alternatives": [],
  "reasoning": "",
  "pros": [],
  "cons": [],
  "confidence_score": "",
  "category": "${category.value}"
}

Response constraints:
- Keep the full response concise and practical.
- confidence_score must be a string numeric value between 0.00 and 1.00.
- reasoning should be clear and actionable in 2-4 sentences.
''';
  }

  String _buildPersonalizationContext(DecisionRequest request) {
    final parts = <String>[];

    if (request.userProfile != null) {
      if (request.userProfile!.budget.isNotEmpty) {
        parts.add('typical budget: ${request.userProfile!.budget}');
      }
      if (request.userProfile!.location.isNotEmpty) {
        parts.add('based in: ${request.userProfile!.location}');
      }
      if (request.userProfile!.preferences.isNotEmpty) {
        parts.add('preferences: ${request.userProfile!.preferences}');
      }
      if (request.userProfile!.userStyle.isNotEmpty) {
        parts.add('style: ${request.userProfile!.userStyle}');
      }
    }

    if (request.pastDecisions.isNotEmpty) {
      final recentChoices = request.pastDecisions
          .take(3)
          .map((d) => d.bestChoice)
          .join(', ');
      parts.add('previously enjoyed: $recentChoices');
    }

    return parts.join('; ');
  }
}
