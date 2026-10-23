import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'daily_challenge.dart';
import 'user_stats.dart';

/// Async SharedPreferences-backed store for [UserStats] and related prefs.
///
/// Writes are fire-and-forget from the caller's perspective; the service
/// awaits them internally so concurrent updates are still serialized by
/// SharedPreferences' single-file model.
class UserStatsService {
  static const hapticsKey = 'pref_haptics_enabled_v1';
  static const challengeKey = 'daily_challenge_v1';
  static const achievementsKey = 'achievements_v1';

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

  /// Returns the previously-saved challenge state, or null when none exists.
  /// Callers (the provider) are responsible for rolling a fresh challenge
  /// when the stored dayKey doesn't match today.
  DailyChallenge? loadChallenge() {
    final raw = _prefs.getString(challengeKey);
    return DailyChallenge.tryDecode(raw);
  }

  Future<void> saveChallenge(DailyChallenge challenge) async {
    await _prefs.setString(challengeKey, challenge.encode());
  }

  Future<void> clearChallenge() async {
    await _prefs.remove(challengeKey);
  }

  /// Loads the persisted set of unlocked achievement ids (raw strings so the
  /// service stays decoupled from the enum definition).
  Set<String> loadAchievements() {
    final raw = _prefs.getString(achievementsKey);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> saveAchievements(Set<String> ids) async {
    await _prefs.setString(achievementsKey, jsonEncode(ids.toList()));
  }

  Future<void> clearAchievements() async {
    await _prefs.remove(achievementsKey);
  }
}
