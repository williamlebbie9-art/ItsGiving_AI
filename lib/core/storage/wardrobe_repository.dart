import 'package:shared_preferences/shared_preferences.dart';

class WardrobeRepository {
  static const _key = 'wardrobe_paths_v1';

  Future<List<String>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_key) ?? <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> save(List<String> paths) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_key, paths);
    } catch (_) {}
  }
}
