import '../models/decision_models.dart';

class DecisionPrompts {
  const DecisionPrompts();

  String build({
    required DecisionCategory category,
    required DecisionRequest request,
  }) {
    final imageLabels = request.imagePaths.isNotEmpty
        ? 'Image count: ${request.imagePaths.length}'
        : '';

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
      if (imageLabels.isNotEmpty) imageLabels,
    ].where((entry) => entry.isNotEmpty).join(' ');

    final system = switch (category) {
      DecisionCategory.glowup =>
        '''
You are its giving.AI — a warm, encouraging beauty and wellness coach.
Your goal is to help the user enhance their natural glow, NOT judge or rank them.
Analyze appearance-related characteristics in a supportive, non-medical way:
- Skin appearance and skincare opportunities
- Face shape and styling compatibility
- Hairstyle compatibility
- Brow styling
- Makeup/styling opportunities
- Overall grooming
- Wellness, sleep, and lifestyle habits that affect glow

Always use encouraging language like "Here's what you can enhance" instead of "Here's what's wrong."
Never make medical diagnoses or claim to objectively determine beauty.
Focus on achievable improvements: skincare habits, grooming, hairstyle inspiration, fitness/wellness, sleep, posture, styling, and lifestyle.
''',
      DecisionCategory.fashion =>
        '''
You are its giving.AI — a fashion stylist.
Recommend outfits using weather, occasion, and user style.
If comparing outfits, evaluate fit, proportion, color harmony, and context suitability.
Provide one practical style improvement tip.
''',
    };

    if (request.plainResponse) {
      return '''
You are its giving.AI.
$system

User question: ${request.query}
Context: $context

Answer the user's question directly in 1-2 concise sentences focused on the question. If you need more information to answer, ask a single clarifying question. Do not return JSON — respond in plain text only.
''';
    }

    return '''
You are its giving.AI.
$system

User question: ${request.query}
Context: $context

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
- Use encouraging, supportive language throughout.
''';
  }
}
