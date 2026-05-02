import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';
import 'user_stats.dart';

/// Async SharedPreferences-backed store for [UserStats], [LessonProgress],
/// and related prefs.
///
/// Writes are fire-and-forget from the caller's perspective; the service
/// awaits them internally so concurrent updates are still serialized by
/// SharedPreferences' single-file model.
class UserStatsService {
  static const hapticsKey = 'pref_haptics_enabled_v1';

  /// Set of achievement ids the player has already seen the unlock toast for.
  /// Stored as JSON list of strings.
  static const achievementsSeenKey = 'achievements_seen_v1';

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

  LessonProgress loadLessonProgress() {
    final raw = _prefs.getString(LessonProgress.storageKey);
    return LessonProgress.tryDecode(raw) ?? LessonProgress.empty();
  }

  Future<void> saveLessonProgress(LessonProgress progress) async {
    await _prefs.setString(LessonProgress.storageKey, progress.encode());
  }

  /// Reset just the lesson-progress slot (used by Settings → Reset progression).
  Future<void> clearLessonProgress() async {
    await _prefs.remove(LessonProgress.storageKey);
  }

  Set<String> loadAchievementsSeen() {
    final raw = _prefs.getStringList(achievementsSeenKey);
    if (raw == null) return <String>{};
    return raw.toSet();
  }

  Future<void> saveAchievementsSeen(Set<String> ids) async {
    await _prefs.setStringList(achievementsSeenKey, ids.toList()..sort());
  }

  Future<void> clearAchievementsSeen() async {
    await _prefs.remove(achievementsSeenKey);
  }
}
