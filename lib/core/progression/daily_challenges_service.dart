import 'package:shared_preferences/shared_preferences.dart';

import 'daily_challenges.dart';

/// SharedPreferences-backed store for the day's challenge slate.
///
/// Persisted as `{date: yyyy-mm-dd, challenges: [...]}` under
/// [DailyChallenges.storageKey]. On day rollover, [loadForToday] regenerates
/// a fresh slate and persists it.
class DailyChallengesService {
  final SharedPreferences _prefs;

  DailyChallengesService(this._prefs);

  static Future<DailyChallengesService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return DailyChallengesService(prefs);
  }

  /// Returns today's challenge list. Regenerates and persists when the stored
  /// snapshot is missing, corrupt, or from a previous day.
  Future<List<DailyChallenge>> loadForToday({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final raw = _prefs.getString(DailyChallenges.storageKey);
    final decoded = DailyChallenges.tryDecodeForToday(raw, today);
    if (decoded != null && decoded.isNotEmpty) return decoded;
    final fresh = DailyChallenges.forDate(today);
    await save(fresh, date: today);
    return fresh;
  }

  Future<void> save(List<DailyChallenge> list, {DateTime? date}) async {
    final stamp = date ??
        (list.isNotEmpty ? list.first.date : DateTime.now());
    await _prefs.setString(
      DailyChallenges.storageKey,
      DailyChallenges.encodeSnapshot(stamp, list),
    );
  }
}
