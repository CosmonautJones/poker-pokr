import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'achievement.dart';

/// SharedPreferences-backed store for the set of achievement IDs the player
/// has already unlocked (and seen the celebration for). Persisted as a JSON
/// string array under [storageKey].
///
/// Unknown IDs (e.g. an achievement removed from the catalog in a future
/// version) are dropped silently on load.
class AchievementsService {
  static const storageKey = 'achievements_unlocked_v1';

  final SharedPreferences _prefs;

  AchievementsService(this._prefs);

  Set<AchievementId> loadUnlocked() {
    final raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return <AchievementId>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      final byName = {for (final id in AchievementId.values) id.name: id};
      return {
        for (final entry in list)
          if (entry is String && byName.containsKey(entry)) byName[entry]!,
      };
    } catch (_) {
      return <AchievementId>{};
    }
  }

  Future<void> saveUnlocked(Set<AchievementId> ids) async {
    final list = ids.map((id) => id.name).toList()..sort();
    await _prefs.setString(storageKey, jsonEncode(list));
  }

  Future<void> clear() async {
    await _prefs.remove(storageKey);
  }
}
