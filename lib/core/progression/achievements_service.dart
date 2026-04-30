import 'package:shared_preferences/shared_preferences.dart';

import 'achievements.dart';

/// SharedPreferences-backed store for [AchievementsState].
///
/// Mirrors the pattern of [UserStatsService] — stores the entire state as a
/// single JSON string under [AchievementsState.storageKey] so the schema can
/// evolve without migrations.
class AchievementsService {
  final SharedPreferences _prefs;

  AchievementsService(this._prefs);

  static Future<AchievementsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return AchievementsService(prefs);
  }

  AchievementsState load() {
    final raw = _prefs.getString(AchievementsState.storageKey);
    return AchievementsState.tryDecode(raw) ?? const AchievementsState.empty();
  }

  Future<void> save(AchievementsState state) async {
    await _prefs.setString(AchievementsState.storageKey, state.encode());
  }

  Future<void> clear() async {
    await _prefs.remove(AchievementsState.storageKey);
  }
}
