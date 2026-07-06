import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decision_models.dart';

class ComparisonRepository {
  static const _key = 'product_comparisons_v1';

  Future<List<ProductComparison>> list() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_key) ?? const [];
      return raw
          .map((entry) => ProductComparison.fromJson(jsonDecode(entry)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<ProductComparison?> getById(String id) async {
    final comparisons = await list();
    try {
      return comparisons.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(ProductComparison comparison) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];

      // Remove if already exists (update case)
      current.removeWhere((entry) {
        try {
          final c = ProductComparison.fromJson(jsonDecode(entry));
          return c.id == comparison.id;
        } catch (_) {
          return false;
        }
      });

      // Add to front
      current.insert(0, jsonEncode(comparison.toJson()));

      // Keep only last 100
      if (current.length > 100) {
        current.removeRange(100, current.length);
      }

      await prefs.setStringList(_key, current);
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_key) ?? <String>[];

      current.removeWhere((entry) {
        try {
          final c = ProductComparison.fromJson(jsonDecode(entry));
          return c.id == id;
        } catch (_) {
          return false;
        }
      });

      await prefs.setStringList(_key, current);
    } catch (_) {}
  }

  Future<List<ProductComparison>> search(String query) async {
    final comparisons = await list();
    final lowerQuery = query.toLowerCase();

    return comparisons.where((c) {
      return c.productAName.toLowerCase().contains(lowerQuery) ||
          c.productBName.toLowerCase().contains(lowerQuery) ||
          c.overview.toLowerCase().contains(lowerQuery) ||
          c.summary.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
