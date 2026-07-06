import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_models.dart';

class AuthRepository {
  static const _key = 'user_account_v1';

  Future<UserAccount?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        return null;
      }
      try {
        return UserAccount.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> save(UserAccount account) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(account.toJson()));
    } catch (_) {}
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (_) {}
  }
}
