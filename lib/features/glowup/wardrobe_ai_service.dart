import 'dart:convert';

List<Map<String, dynamic>> parseWardrobeHistory(List<String> rawHistory) {
  final parsed = <Map<String, dynamic>>[];

  for (final entry in rawHistory) {
    if (entry.trim().isEmpty) continue;

    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) {
        final map = decoded is Map ? Map<String, dynamic>.from(decoded) : null;
        if (map == null) continue;
        parsed.add(map);
        continue;
      }
      parsed.add(decoded);
    } catch (_) {
      continue;
    }
  }

  return parsed..sort((a, b) {
    final aDate =
        DateTime.tryParse((a['createdAt'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final bDate =
        DateTime.tryParse((b['createdAt'] ?? '').toString()) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return bDate.compareTo(aDate);
  });
}

String buildAestheticPlanContext(
  String aesthetic, {
  String? goal,
  String? lifestyle,
}) {
  final normalized = aesthetic.trim().isEmpty ? 'Clean Girl' : aesthetic.trim();
  final base = switch (normalized.toLowerCase()) {
    'old money' =>
      'Old Money: lean into timeless elegance, polished grooming, elevated basics, and graceful routines that feel quietly luxurious.',
    'soft girl' =>
      'Soft Girl: focus on comforting textures, gentle rituals, femininity, and soft confidence without overwhelming the routine.',
    'clean girl' =>
      'Clean Girl: keep it fresh, minimal, and polished with a simple skincare-grooming rhythm and easy neutrals.',
    'dark feminine' =>
      'Dark Feminine: build a confident and refined presence through elegant silhouettes, deep tones, and disciplined self-care.',
    'coquette' =>
      'Coquette: keep the look romantic, feminine, and intentional with polished details, soft beauty, and gracious habits.',
    'baddie' =>
      'Baddie: lean into confidence, strong styling, Grooming, and a structured routine that feels bold but still easy to sustain.',
    'goth' =>
      'Goth: create a dark, expressive style with intentional self-care, mood-driven routines, and quiet confidence.',
    _ =>
      '$normalized: keep the plan anchored to the user\'s chosen style while preserving realistic, sustainable routines.',
  };

  final goalText = goal != null && goal.trim().isNotEmpty
      ? 'Goal: $goal.'
      : 'Goal: build consistent glow-up habits.';
  final lifestyleText = lifestyle != null && lifestyle.trim().isNotEmpty
      ? 'Lifestyle: $lifestyle.'
      : 'Lifestyle: balanced daily life.';

  return '$base $goalText $lifestyleText';
}

bool validateWardrobeReport(Map<String, dynamic> data) {
  final requiredNumericKeys = ['aestheticMatchScore', 'fashionabilityScore'];

  for (final key in requiredNumericKeys) {
    final value = data[key];
    if (value is! num) return false;
  }

  final requiredTextKeys = [
    'overallVerdict',
    'whatGetsRight',
    'whatCouldImprove',
    'colourCoordination',
    'silhouetteAndProportions',
    'layeringAndAccessories',
    'aestheticAlignment',
  ];

  for (final key in requiredTextKeys) {
    final value = data[key];
    if (value == null || value.toString().trim().isEmpty) return false;
  }

  final requiredLists = [
    'improvementSuggestions',
    'stylingAlternatives',
    'occasionSuggestions',
  ];

  for (final key in requiredLists) {
    final value = data[key];
    if (value is! List || value.isEmpty) return false;
  }

  return true;
}
