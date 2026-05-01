import 'package:shared_preferences/shared_preferences.dart';

import 'unlocked_achievements.dart';
import 'user_stats.dart';

/// Async SharedPreferences-backed store for [UserStats] and related prefs.
///
/// Writes are fire-and-forget from the caller's perspective; the service
/// awaits them internally so concurrent updates are still serialized by
/// SharedPreferences' single-file model.
class UserStatsService {
  static const hapticsKey = 'pref_haptics_enabled_v1';

  final SharedPreferences _prefs;

  UserStatsService(this._prefs);

  static Future<UserStatsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return UserStatsService(prefs);
  }

  UserStats loadStats() {
    final raw = _prefs.getString(UserStats.storageKey);
    return UserStats.tryDecode(raw) ?? const UserStats.empty();
  }

  Future<void> saveStats(UserStats stats) async {
    await _prefs.setString(UserStats.storageKey, stats.encode());
  }

  bool loadHapticsEnabled() => _prefs.getBool(hapticsKey) ?? true;

  Future<void> saveHapticsEnabled(bool enabled) async {
    await _prefs.setBool(hapticsKey, enabled);
  }

  UnlockedAchievements loadUnlocks() {
    final raw = _prefs.getString(UnlockedAchievements.storageKey);
    return UnlockedAchievements.tryDecode(raw);
  }

  Future<void> saveUnlocks(UnlockedAchievements unlocks) async {
    await _prefs.setString(
      UnlockedAchievements.storageKey,
      unlocks.encode(),
    );
  }
}
