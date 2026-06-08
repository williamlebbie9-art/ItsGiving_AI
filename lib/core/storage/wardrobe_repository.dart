import 'package:shared_preferences/shared_preferences.dart';

class WardrobeRepository {
  static const _key = 'wardrobe_paths_v1';

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? <String>[];
  }

  Future<void> save(List<String> paths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, paths);
  }
}
