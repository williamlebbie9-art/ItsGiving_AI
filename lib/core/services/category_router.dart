import '../models/decision_models.dart';

class CategoryRouter {
  const CategoryRouter();

  DecisionCategory route(String query) {
    final lower = query.toLowerCase();

    if (lower.contains('outfit') ||
        lower.contains('style') ||
        lower.contains('wear') ||
        lower.contains('fashion')) {
      return DecisionCategory.fashion;
    }

    return DecisionCategory.glowup;
  }
}
