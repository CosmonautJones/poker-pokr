import 'package:poker_trainer/features/onboarding/data/onboarding_prefs.dart';
import 'package:poker_trainer/features/settings/domain/personalization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'achievements.dart';
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

  AchievementProgress loadAchievements() {
    final raw = _prefs.getString(AchievementProgress.storageKey);
    return AchievementProgress.tryDecode(raw) ??
        const AchievementProgress.empty();
  }

  Future<void> saveAchievements(AchievementProgress progress) async {
    await _prefs.setString(AchievementProgress.storageKey, progress.encode());
  }

  bool loadOnboardingSeen() => _prefs.getBool(OnboardingFlag.key) ?? false;

  Future<void> saveOnboardingSeen(bool seen) async {
    await _prefs.setBool(OnboardingFlag.key, seen);
  }

  PersonalizationSettings loadPersonalization() {
    final raw = _prefs.getString(PersonalizationSettings.storageKey);
    return PersonalizationSettings.tryDecode(raw) ??
        const PersonalizationSettings.defaults();
  }

  Future<void> savePersonalization(PersonalizationSettings settings) async {
    await _prefs.setString(
      PersonalizationSettings.storageKey,
      settings.encode(),
    );
  }
}
