import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences-backed persistence for the unlocked-achievement set.
///
/// We store the set as a JSON-encoded list of ids — `SharedPreferences` does
/// have a `setStringList` API, but using JSON keeps the on-disk shape
/// identical to the (in-memory) [Set] and allows us to evolve the schema
/// later without an explicit migration.
class AchievementService {
  static const storageKey = 'achievements_unlocked_v1';

  final SharedPreferences _prefs;

  AchievementService(this._prefs);

  static Future<AchievementService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AchievementService(prefs);
  }

  Set<String> loadUnlocked() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toSet();
      }
      return <String>{};
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveUnlocked(Set<String> ids) async {
    final list = ids.toList()..sort();
    await _prefs.setString(storageKey, jsonEncode(list));
  }
}
