import 'dart:convert';

enum DecisionCategory { food, travel, products, fashion }

extension DecisionCategoryX on DecisionCategory {
  String get value => switch (this) {
    DecisionCategory.food => 'food',
    DecisionCategory.travel => 'travel',
    DecisionCategory.products => 'products',
    DecisionCategory.fashion => 'fashion',
  };

  String get title => switch (this) {
    DecisionCategory.food => 'Food',
    DecisionCategory.travel => 'Travel',
    DecisionCategory.products => 'Products',
    DecisionCategory.fashion => 'Fashion',
  };

  static DecisionCategory fromValue(String value) {
    return DecisionCategory.values.firstWhere(
      (category) => category.value == value,
      orElse: () => DecisionCategory.products,
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

  Map<String, dynamic> toJson() {
    return {
      'best_choice': bestChoice,
      'alternatives': alternatives,
      'reasoning': reasoning,
      'pros': pros,
      'cons': cons,
      'confidence_score': confidenceScore,
      'category': category.value,
    };
  }

  factory DecisionResult.fromJson(Map<String, dynamic> json) {
    dynamic readValue(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key) && json[key] != null) {
          return json[key];
        }
      }
      return null;
    }

    String asReadableText(dynamic value) {
      if (value == null) {
        return '';
      }
      if (value is String) {
        return value.trim();
      }
      if (value is num || value is bool) {
        return value.toString();
      }
      if (value is List) {
        return value
            .map(asReadableText)
            .where((item) => item.isNotEmpty)
            .join(', ');
      }
      if (value is Map) {
        final map = Map<String, dynamic>.from(value);
        String primary = '';
        for (final candidate in [
          map['name'],
          map['title'],
          map['destination'],
          map['place'],
          map['city'],
          map['item'],
          map['choice'],
        ]) {
          if (candidate != null && candidate.toString().trim().isNotEmpty) {
            primary = candidate.toString().trim();
            break;
          }
        }

        final extras = <String>[];
        if (map['budget'] != null &&
            map['budget'].toString().trim().isNotEmpty) {
          extras.add('budget ${map['budget']}');
        }
        if (map['price'] != null && map['price'].toString().trim().isNotEmpty) {
          extras.add('price ${map['price']}');
        }
        if (map['type'] != null && map['type'].toString().trim().isNotEmpty) {
          extras.add(map['type'].toString().trim());
        }

        final itinerary = map['itinerary'];
        if (itinerary is Map && itinerary['days'] != null) {
          extras.add('${itinerary['days']} days');
        }

        if (primary.isNotEmpty) {
          return [primary, ...extras].join(' • ');
        }

        return map.entries
            .take(3)
            .map((entry) => '${entry.key}: ${asReadableText(entry.value)}')
            .join(', ');
      }
      return value.toString().trim();
    }

    List<String> asStringList(dynamic value) {
      if (value is List) {
        return value
            .map(asReadableText)
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }
      if (value is String) {
        return value
            .split(RegExp(r'[\n;•]+'))
            .map((item) => item.replaceFirst(RegExp(r'^[-*\s]+'), '').trim())
            .where((item) => item.isNotEmpty)
            .toList(growable: false);
      }

      final single = asReadableText(value);
      return single.isEmpty ? const [] : <String>[single];
    }

    final confidenceText = asReadableText(
      readValue(['confidence_score', 'confidenceScore', 'confidence']),
    );

    return DecisionResult(
      bestChoice: asReadableText(
        readValue(['best_choice', 'bestChoice', 'best', 'recommendation']),
      ),
      alternatives: asStringList(
        readValue(['alternatives', 'options', 'other_choices', 'otherChoices']),
      ),
      reasoning: asReadableText(
        readValue(['reasoning', 'explanation', 'why', 'summary']),
      ),
      pros: asStringList(readValue(['pros', 'benefits', 'strengths'])),
      cons: asStringList(
        readValue(['cons', 'drawbacks', 'weaknesses', 'watchouts']),
      ),
      confidenceScore: confidenceText.isEmpty ? '0.65' : confidenceText,
      category: DecisionCategoryX.fromValue(
        (readValue(['category']) ?? DecisionCategory.products.value).toString(),
      ),
    );
  }
}

class DecisionHistoryItem {
  const DecisionHistoryItem({
    required this.id,
    required this.createdAt,
    required this.query,
    required this.result,
  });

  final String id;
  final DateTime createdAt;
  final String query;
  final DecisionResult result;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'query': query,
      'result': result.toJson(),
    };
  }

  factory DecisionHistoryItem.fromJson(Map<String, dynamic> json) {
    return DecisionHistoryItem(
      id: (json['id'] ?? '').toString(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      query: (json['query'] ?? '').toString(),
      result: DecisionResult.fromJson(
        Map<String, dynamic>.from(json['result'] as Map? ?? const {}),
      ),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'budget': budget,
      'location': location,
      'preferences': preferences,
      'userStyle': userStyle,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      budget: (json['budget'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      preferences: (json['preferences'] ?? '').toString(),
      userStyle: (json['userStyle'] ?? '').toString(),
    );
  }
}

/// Represents a product image with optional cropped version
class ProductImage {
  const ProductImage({
    required this.originalPath,
    this.croppedPath,
    this.extractedText = '',
  });

  final String originalPath;
  final String? croppedPath;
  final String extractedText;

  Map<String, dynamic> toJson() {
    return {
      'originalPath': originalPath,
      'croppedPath': croppedPath,
      'extractedText': extractedText,
    };
  }

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      originalPath: (json['originalPath'] ?? '').toString(),
      croppedPath: json['croppedPath'] as String?,
      extractedText: (json['extractedText'] ?? '').toString(),
    );
  }
}

/// Detailed product comparison result with analysis of two products
class ProductComparison {
  const ProductComparison({
    required this.id,
    required this.productAName,
    required this.productBName,
    required this.productAImage,
    required this.productBImage,
    required this.createdAt,
    required this.overview,
    required this.specifications,
    required this.ingredients,
    required this.advantagesA,
    required this.advantagesB,
    required this.majorDifferences,
    required this.valueForMoney,
    required this.qualityAssessment,
    required this.summary,
    required this.recommendation,
    required this.alternativeRecommendations,
    required this.productADetails,
    required this.productBDetails,
  });

  final String id;
  final String productAName;
  final String productBName;
  final ProductImage productAImage;
  final ProductImage productBImage;
  final DateTime createdAt;
  final String overview;
  final String specifications;
  final String ingredients;
  final String advantagesA;
  final String advantagesB;
  final String majorDifferences;
  final String valueForMoney;
  final String qualityAssessment;
  final String summary;
  final String recommendation; // e.g., "Product A"
  final Map<String, String>
  alternativeRecommendations; // e.g., {"Best Budget": "Product B", "Best Value": "Product A"}
  final Map<String, String> productADetails;
  final Map<String, String> productBDetails;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'productAName': productAName,
      'productBName': productBName,
      'productAImage': productAImage.toJson(),
      'productBImage': productBImage.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'overview': overview,
      'specifications': specifications,
      'ingredients': ingredients,
      'advantagesA': advantagesA,
      'advantagesB': advantagesB,
      'majorDifferences': majorDifferences,
      'valueForMoney': valueForMoney,
      'qualityAssessment': qualityAssessment,
      'summary': summary,
      'recommendation': recommendation,
      'alternativeRecommendations': alternativeRecommendations,
      'productADetails': productADetails,
      'productBDetails': productBDetails,
    };
  }

  factory ProductComparison.fromJson(Map<String, dynamic> json) {
    return ProductComparison(
      id: (json['id'] ?? '').toString(),
      productAName: (json['productAName'] ?? '').toString(),
      productBName: (json['productBName'] ?? '').toString(),
      productAImage: ProductImage.fromJson(
        Map<String, dynamic>.from(json['productAImage'] as Map? ?? const {}),
      ),
      productBImage: ProductImage.fromJson(
        Map<String, dynamic>.from(json['productBImage'] as Map? ?? const {}),
      ),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      overview: (json['overview'] ?? '').toString(),
      specifications: (json['specifications'] ?? '').toString(),
      ingredients: (json['ingredients'] ?? '').toString(),
      advantagesA: (json['advantagesA'] ?? '').toString(),
      advantagesB: (json['advantagesB'] ?? '').toString(),
      majorDifferences: (json['majorDifferences'] ?? '').toString(),
      valueForMoney: (json['valueForMoney'] ?? '').toString(),
      qualityAssessment: (json['qualityAssessment'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      recommendation: (json['recommendation'] ?? '').toString(),
      alternativeRecommendations: Map<String, String>.from(
        json['alternativeRecommendations'] as Map? ?? const {},
      ),
      productADetails: Map<String, String>.from(
        json['productADetails'] as Map? ?? const {},
      ),
      productBDetails: Map<String, String>.from(
        json['productBDetails'] as Map? ?? const {},
      ),
    );
  }
}
