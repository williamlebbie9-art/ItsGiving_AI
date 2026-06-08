import '../models/decision_models.dart';

class CategoryRouter {
  const CategoryRouter();

  DecisionCategory route(String query) {
    final normalized = query.toLowerCase();

    final scores = <DecisionCategory, int>{
      DecisionCategory.food: _score(normalized, const {
        'restaurant': 4,
        'food': 4,
        'eat': 3,
        'dinner': 3,
        'lunch': 3,
        'breakfast': 3,
        'cafe': 3,
        'menu': 2,
        'delivery': 2,
        'date night': 2,
      }),
      DecisionCategory.travel: _score(normalized, const {
        'travel': 4,
        'trip': 4,
        'vacation': 4,
        'destination': 4,
        'flight': 3,
        'hotel': 3,
        'itinerary': 3,
        'weekend getaway': 3,
        'visa': 2,
        'tour': 2,
      }),
      DecisionCategory.products: _score(normalized, const {
        'buy': 4,
        'product': 4,
        'phone': 4,
        'laptop': 4,
        'headphones': 3,
        'compare': 3,
        'best under': 3,
        'durability': 2,
        'value for money': 3,
        'warranty': 2,
      }),
      DecisionCategory.fashion: _score(normalized, const {
        'wear': 4,
        'outfit': 4,
        'style': 4,
        'fashion': 4,
        'look': 3,
        'wardrobe': 3,
        'sneakers': 2,
        'jacket': 2,
        'color palette': 2,
        'dress code': 3,
      }),
    };

    // Context cues that are strong indicators for a category.
    if (_containsAny(normalized, const ['weather', 'occasion', 'dress code'])) {
      scores[DecisionCategory.fashion] =
          (scores[DecisionCategory.fashion] ?? 0) + 2;
    }
    if (_containsAny(normalized, const ['budget', '\$', 'under '])) {
      scores[DecisionCategory.products] =
          (scores[DecisionCategory.products] ?? 0) + 1;
      scores[DecisionCategory.food] = (scores[DecisionCategory.food] ?? 0) + 1;
      scores[DecisionCategory.travel] =
          (scores[DecisionCategory.travel] ?? 0) + 1;
    }

    final best = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (best.isNotEmpty && best.first.value > 0) {
      return best.first.key;
    }
    return DecisionCategory.products;
  }

  int _score(String source, Map<String, int> weightedKeywords) {
    var total = 0;
    weightedKeywords.forEach((keyword, weight) {
      if (source.contains(keyword)) {
        total += weight;
      }
    });
    return total;
  }

  bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) {
        return true;
      }
    }
    return false;
  }
}
