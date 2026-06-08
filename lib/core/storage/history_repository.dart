import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decision_models.dart';

class HistoryRepository {
  static const _key = 'decision_history_v1';

  Future<List<DecisionHistoryItem>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? const [];
    return raw
        .map((entry) => DecisionHistoryItem.fromJson(jsonDecode(entry)))
        .toList(growable: false);
  }

  Future<void> add(DecisionHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_key) ?? <String>[];
    current.insert(0, jsonEncode(item.toJson()));
    if (current.length > 100) {
      current.removeRange(100, current.length);
    }
    await prefs.setStringList(_key, current);
  }
}
