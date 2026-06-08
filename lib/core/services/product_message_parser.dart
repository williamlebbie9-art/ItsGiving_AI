class ProductParseResult {
  const ProductParseResult({
    this.productName = '',
    this.budget = '',
    this.location = '',
    this.preferences = '',
    this.compareOptions = const [],
  });

  final String productName;
  final String budget;
  final String location;
  final String preferences;
  final List<String> compareOptions;
}

class ProductMessageParser {
  const ProductMessageParser();

  ProductParseResult parse(
    String text, {
    String? expectedField,
    bool compareMode = false,
  }) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const ProductParseResult();
    }

    final normalized = raw.toLowerCase();
    final compareOptions = compareMode
        ? _extractCompareOptions(raw)
        : const <String>[];

    var budget = _extractBudget(raw);
    var location = _extractLocation(raw);
    var preferences = _extractPreferences(raw, normalized);
    var productName = _extractProductName(
      raw,
      compareOptions: compareOptions,
      budget: budget,
      location: location,
      preferences: preferences,
    );

    if (expectedField == 'product' && productName.isEmpty) {
      productName = raw;
    }
    if (expectedField == 'budget' && budget.isEmpty) {
      budget = raw;
    }
    if (expectedField == 'location' && location.isEmpty) {
      location = raw;
    }
    if (expectedField == 'preferences' && preferences.isEmpty) {
      preferences = raw;
    }

    return ProductParseResult(
      productName: productName,
      budget: budget,
      location: location,
      preferences: preferences,
      compareOptions: compareOptions,
    );
  }

  List<String> _extractCompareOptions(String raw) {
    final normalized = raw.toLowerCase();
    if (!normalized.contains('compare') && !normalized.contains(' vs ')) {
      return const [];
    }

    final cleaned = raw
        .replaceFirst(RegExp(r'^\s*compare\s*', caseSensitive: false), '')
        .trim();

    return cleaned
        .split(RegExp(r'\s+vs\s+|\s*,\s*', caseSensitive: false))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }

  String _extractBudget(String raw) {
    final match = RegExp(
      r'([$£€]\s?\d[\d,]*(?:\.\d{1,2})?|\bunder\s+\d[\d,]*|\b\d{2,6}(?:\.\d{1,2})?\b(?:\s?(?:usd|gbp|eur|dollars?|pounds?|euros?))?)',
      caseSensitive: false,
    ).firstMatch(raw);

    return match?.group(0)?.trim() ?? '';
  }

  String _extractLocation(String raw) {
    final patterns = [
      RegExp(r'\bin\s+([A-Za-z][A-Za-z\s&\-]{1,40})', caseSensitive: false),
      RegExp(r'\bfrom\s+([A-Za-z][A-Za-z\s&\-]{1,40})', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) {
        return match.group(1)?.trim() ?? '';
      }
    }
    return '';
  }

  String _extractPreferences(String raw, String normalized) {
    const hints = [
      'battery',
      'camera',
      'gaming',
      'durable',
      'cheap',
      'affordable',
      'premium',
      'storage',
      'ram',
      'fast',
      'wireless',
      'noise',
      'performance',
    ];

    return hints.any(normalized.contains) ? raw : '';
  }

  String _extractProductName(
    String raw, {
    required List<String> compareOptions,
    required String budget,
    required String location,
    required String preferences,
  }) {
    if (compareOptions.isNotEmpty) {
      return compareOptions.join(' vs ');
    }

    var cleaned = raw.trim();
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(?:i need|i want|looking for|find me|show me)\s+',
        caseSensitive: false,
      ),
      '',
    );
    if (budget.isNotEmpty) {
      cleaned = cleaned.replaceFirst(budget, '').trim();
    }
    if (location.isNotEmpty) {
      cleaned = cleaned
          .replaceFirst(
            RegExp(
              '\\b(?:in|from)\\s+${RegExp.escape(location)}',
              caseSensitive: false,
            ),
            '',
          )
          .trim();
    }
    if (preferences.isNotEmpty) {
      cleaned = cleaned.replaceFirst(preferences, '').trim();
    }

    cleaned = cleaned
        .replaceAll(
          RegExp(r'\b(with|that has|for)\b.*$', caseSensitive: false),
          '',
        )
        .trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }
}
