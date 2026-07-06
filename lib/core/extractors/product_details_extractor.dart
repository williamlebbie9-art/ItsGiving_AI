/// Extracts section-specific content from AI response text that uses
/// labeled section markers like `[PRICE_AND_PURCHASE] ... [/PRICE_AND_PURCHASE]`.
///
/// If no markers are found, falls back to the full text.
class ProductDetailsExtractor {
  const ProductDetailsExtractor();

  /// Section labels used in per-product AI prompts.
  static const List<String> sectionLabels = [
    'PRICE_AND_PURCHASE',
    'EFFECTS_BENEFITS',
    'NUTRIENTS',
    'INGREDIENTS',
    'BENEFITS',
    'PROS_CONS',
    'PROCESSED_CHEMICALS',
    'CALORIES',
    'RECOMMENDATION',
    // Skincare markers
    'ACNE_FRIENDLINESS',
    'SENSITIVE_SKIN_SUITABILITY',
    'COMEDOGENIC_RISK',
    'ACTIVE_INGREDIENTS',
    'FRAGRANCE_CONTENT',
    'OVERALL_SKIN_SAFETY',
    // Perfume markers
    'LONGEVITY',
    'SILLAGE',
    'FRAGRANCE_NOTES',
    'OCCASION_SUITABILITY',
    'SEASON_SUITABILITY',
    'GENDER_NEUTRALITY',
    'VALUE_FOR_MONEY',
  ];

  /// Extracts a specific section from [text] using markers like
  /// `[PRICE_AND_PURCHASE] ... [/PRICE_AND_PURCHASE]`.
  /// Returns the section content, or [fallback] if not found.
  String extract(String text, String label, {String fallback = ''}) {
    final regex = RegExp(
      r'\[' +
          RegExp.escape(label) +
          r'\](.*?)\[\/' +
          RegExp.escape(label) +
          r'\]',
      caseSensitive: false,
      dotAll: true,
    );
    final match = regex.firstMatch(text);
    if (match != null) {
      return match.group(1)!.trim();
    }
    // Also try simpler patterns like "LABEL: content" on its own line
    final simpleRegex = RegExp(
      r'^' + RegExp.escape(label) + r'\s*:\s*(.+)$',
      caseSensitive: false,
      multiLine: true,
      dotAll: false,
    );
    final simpleMatch = simpleRegex.firstMatch(text);
    if (simpleMatch != null) {
      return simpleMatch.group(1)!.trim();
    }
    return fallback;
  }

  /// Checks if the text has any section markers.
  bool hasMarkers(String text) {
    return sectionLabels.any((label) => text.contains('[$label]'));
  }

  /// Parses the [pros] and [cons] lists from a PROS_CONS section.
  /// Expects lines prefixed with + or -.
  MapEntry<List<String>, List<String>> parseProsCons(String prosConsText) {
    if (prosConsText.isEmpty) {
      return const MapEntry([], []);
    }

    final pros = <String>[];
    final cons = <String>[];

    for (final line in prosConsText.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('+') || trimmed.startsWith('PROS:')) {
        pros.add(trimmed.replaceFirst(RegExp(r'^\+|^PROS:\s*'), '').trim());
      } else if (trimmed.startsWith('-') || trimmed.startsWith('CONS:')) {
        cons.add(trimmed.replaceFirst(RegExp(r'^-|^CONS:\s*'), '').trim());
      }
    }
    return MapEntry(pros, cons);
  }
}
