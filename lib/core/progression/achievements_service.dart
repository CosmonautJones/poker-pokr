import 'package:shared_preferences/shared_preferences.dart';

import 'achievements.dart';

/// SharedPreferences-backed store for the player's achievement list.
///
/// Persisted under [Achievements.storageKey] as a JSON array. Independent
/// from [UserStats] so achievements can be wiped/reset without touching XP.
class AchievementsService {
  final SharedPreferences _prefs;

  AchievementsService(this._prefs);

  static Future<AchievementsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AchievementsService(prefs);
  }

  List<Achievement> load() {
    final raw = _prefs.getString(Achievements.storageKey);
    final decoded = Achievement.tryDecodeList(raw);
    if (decoded == null || decoded.isEmpty) return Achievements.defaults();
    // Reconcile against the live catalog: definitions added since the saved
    // snapshot appear locked; saved entries whose definition is gone are
    // dropped silently.
    final byId = {for (final a in decoded) a.definitionId: a};
    return Achievements.all
        .map((d) => byId[d.id] ?? Achievement(definitionId: d.id))
        .toList(growable: true);
  }

  Future<void> save(List<Achievement> list) async {
    await _prefs.setString(Achievements.storageKey, Achievement.encodeList(list));
  }
}
