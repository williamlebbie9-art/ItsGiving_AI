class TravelParseResult {
  const TravelParseResult({
    this.destination = '',
    this.budget = '',
    this.interests = '',
    this.tripType = '',
  });

  final String destination;
  final String budget;
  final String interests;
  final String tripType;
}

class TravelMessageParser {
  const TravelMessageParser();

  TravelParseResult parse(String text, {String? expectedField}) {
    final raw = text.trim();
    if (raw.isEmpty) {
      return const TravelParseResult();
    }

    final normalized = raw.toLowerCase();

    var tripType = _extractTripType(normalized);
    var interests = _extractInterests(raw, normalized);
    var budget = _extractBudget(raw, normalized, expectedField: expectedField);
    var destination = _extractDestination(
      raw,
      normalized,
      expectedField: expectedField,
      extractedBudget: budget,
    );

    if (expectedField == 'tripType' && tripType.isEmpty) {
      tripType = raw;
    }
    if (expectedField == 'interests' && interests.isEmpty) {
      interests = raw;
    }
    if (expectedField == 'budget' && budget.isEmpty) {
      budget = raw;
    }
    if (expectedField == 'destination' && destination.isEmpty) {
      destination = _cleanDestination(raw);
    }

    return TravelParseResult(
      destination: destination,
      budget: budget,
      interests: interests,
      tripType: tripType,
    );
  }

  String _extractTripType(String normalized) {
    if (normalized.contains('vacation') ||
        normalized.contains('holiday') ||
        normalized.contains('honeymoon') ||
        normalized.contains('getaway')) {
      return 'vacation';
    }

    if (normalized.contains('business') ||
        normalized.contains('work trip') ||
        normalized.contains('conference')) {
      return 'business';
    }

    return '';
  }

  String _extractInterests(String raw, String normalized) {
    const keywords = [
      'beach',
      'beaches',
      'museum',
      'hiking',
      'nightlife',
      'food',
      'shopping',
      'adventure',
      'culture',
      'relax',
      'nature',
      'romantic',
      'family',
      'luxury',
    ];

    return keywords.any(normalized.contains) ? raw : '';
  }

  String _extractBudget(
    String raw,
    String normalized, {
    String? expectedField,
  }) {
    final budgetPattern = RegExp(
      r'([$£€]\s?\d[\d,]*(?:\.\d{1,2})?|\b\d{2,6}(?:\.\d{1,2})?\b(?:\s?(?:usd|gbp|eur|dollars?|pounds?|euros?))?)',
      caseSensitive: false,
    );

    final match = budgetPattern.firstMatch(raw);
    if (match == null) {
      return '';
    }

    final value = match.group(0)?.trim() ?? '';
    if (value.isEmpty) {
      return '';
    }

    final numericValue = double.tryParse(
      value.replaceAll(RegExp(r'[^\d.]'), ''),
    );

    final hasBudgetHint =
        normalized.contains('budget') ||
        normalized.contains('cost') ||
        normalized.contains('affordable') ||
        normalized.contains('cheap') ||
        normalized.contains('luxury') ||
        normalized.contains('under ') ||
        normalized.contains(r'$') ||
        normalized.contains('£') ||
        normalized.contains('€') ||
        normalized.contains('usd') ||
        normalized.contains('gbp') ||
        normalized.contains('eur');

    if (expectedField == 'budget' ||
        hasBudgetHint ||
        (numericValue ?? 0) >= 50) {
      return value;
    }

    return '';
  }

  String _extractDestination(
    String raw,
    String normalized, {
    String? expectedField,
    String extractedBudget = '',
  }) {
    final patterns = [
      RegExp(
        r"(?:travel to|going to|go to|visit|in|to)\s+([a-z][a-z\s,&\-']+)",
        caseSensitive: false,
      ),
      RegExp(
        r"(?:destination|place)\s*[:\-]?\s*([a-z][a-z\s,&\-']+)",
        caseSensitive: false,
      ),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(raw);
      if (match != null) {
        final candidate = _cleanDestination(match.group(1) ?? '');
        if (candidate.isNotEmpty) {
          return candidate;
        }
      }
    }

    final shortTextPattern = RegExp(r"^[A-Za-z][A-Za-z\s,&\-']{1,40}$");
    final leadingDestination = extractedBudget.isEmpty
        ? ''
        : _cleanDestination(raw.split(extractedBudget).first);

    if (leadingDestination.isNotEmpty &&
        shortTextPattern.hasMatch(leadingDestination)) {
      return leadingDestination;
    }

    if (expectedField == 'destination' &&
        shortTextPattern.hasMatch(raw) &&
        extractedBudget.isEmpty) {
      return _cleanDestination(raw);
    }

    if (!normalized.contains('budget') &&
        !normalized.contains('nightlife') &&
        !normalized.contains('beach') &&
        !normalized.contains('culture') &&
        shortTextPattern.hasMatch(raw) &&
        extractedBudget.isEmpty) {
      return _cleanDestination(raw);
    }

    return '';
  }

  String _cleanDestination(String value) {
    var cleaned = value.trim();
    cleaned = cleaned.replaceAll(
      RegExp(r'^(?:to|in)\s+', caseSensitive: false),
      '',
    );
    cleaned = cleaned
        .split(
          RegExp(
            r'\b(?:for|with|on|budget|and|where|because)\b',
            caseSensitive: false,
          ),
        )
        .first
        .trim();
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }
}
