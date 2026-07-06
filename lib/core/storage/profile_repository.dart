import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decision_models.dart';

class ProfileRepository {
  static const _key = 'user_profile_v1';

  Future<UserProfile> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) {
        return const UserProfile();
      }
      return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const UserProfile();
    }
  }

  Future<void> save(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(profile.toJson()));
    } catch (_) {}
  }
}
