import 'dart:convert';

enum DecisionCategory { glowup, fashion }

extension DecisionCategoryX on DecisionCategory {
  String get value => switch (this) {
    DecisionCategory.glowup => 'glowup',
    DecisionCategory.fashion => 'fashion',
  };

  String get title => switch (this) {
    DecisionCategory.glowup => 'Glow-Up',
    DecisionCategory.fashion => 'Fashion',
  };

  static DecisionCategory fromValue(String value) {
    return DecisionCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => DecisionCategory.glowup,
    );
  }
}

class DecisionRequest {
  const DecisionRequest({
    required this.query,
    this.manualCategory,
    this.compareOptions = const [],
    this.budget,
    this.location,
    this.preferences,
    this.plainResponse = false,
    this.weather,
    this.occasion,
    this.userStyle,
    this.imagePaths = const [],
    this.userProfile,
    this.pastDecisions = const [],
    this.operation,
  });

  final String query;
  final DecisionCategory? manualCategory;
  final List<String> compareOptions;
  final String? budget;
  final String? location;
  final String? preferences;
  final bool plainResponse;
  final String? weather;
  final String? occasion;
  final String? userStyle;
  final List<String> imagePaths;
  final UserProfile? userProfile;
  final List<DecisionResult> pastDecisions;

  /// Which usage bucket this request consumes on the backend:
  /// 'faceScan', 'coachInsight', or 'plan'.
  final String? operation;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'manualCategory': manualCategory?.value,
      'compareOptions': compareOptions,
      'plainResponse': plainResponse,
      'budget': budget,
      'location': location,
      'preferences': preferences,
      'weather': weather,
      'occasion': occasion,
      'userStyle': userStyle,
      'imagePaths': imagePaths,
      'userProfile': userProfile?.toJson(),
      'pastDecisions': pastDecisions.map((d) => d.toJson()).toList(),
      'operation': operation,
    };
  }

  String toCacheKey() => jsonEncode(toJson());
}

class DecisionResult {
  const DecisionResult({
    required this.bestChoice,
    required this.alternatives,
    required this.reasoning,
    required this.pros,
    required this.cons,
    required this.confidenceScore,
    required this.category,
  });

  final String bestChoice;
  final List<String> alternatives;
  final String reasoning;
  final List<String> pros;
  final List<String> cons;
  final String confidenceScore;
  final DecisionCategory category;

  factory DecisionResult.fromJson(Map<String, dynamic> json) {
    return DecisionResult(
      bestChoice: (json['best_choice'] ?? json['bestChoice'] ?? '').toString(),
      alternatives: _toStringList(json['alternatives'] ?? json['options']),
      reasoning: (json['reasoning'] ?? json['explanation'] ?? '').toString(),
      pros: _toStringList(json['pros'] ?? json['benefits']),
      cons: _toStringList(json['cons'] ?? json['drawbacks']),
      confidenceScore:
          (json['confidence_score'] ?? json['confidenceScore'] ?? '0.80')
              .toString(),
      category: DecisionCategoryX.fromValue(
        (json['category'] ?? 'glowup').toString(),
      ),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    if (value is String) {
      return value
          .split(RegExp(r'\n|;|•'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> toJson() => {
    'best_choice': bestChoice,
    'alternatives': alternatives,
    'reasoning': reasoning,
    'pros': pros,
    'cons': cons,
    'confidence_score': confidenceScore,
    'category': category.value,
  };
}

class UserProfile {
  const UserProfile({
    this.budget = '',
    this.location = '',
    this.preferences = '',
    this.userStyle = '',
  });

  final String budget;
  final String location;
  final String preferences;
  final String userStyle;

  Map<String, dynamic> toJson() => {
    'budget': budget,
    'location': location,
    'preferences': preferences,
    'userStyle': userStyle,
  };
}

class DecisionHistoryItem {
  const DecisionHistoryItem({
    required this.bestChoice,
    required this.category,
    required this.timestamp,
  });

  final String bestChoice;
  final String category;
  final DateTime timestamp;

  factory DecisionHistoryItem.fromJson(Map<String, dynamic> json) {
    return DecisionHistoryItem(
      bestChoice: (json['bestChoice'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'bestChoice': bestChoice,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
  };
}
