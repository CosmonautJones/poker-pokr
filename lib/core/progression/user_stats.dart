import 'dart:convert';
import 'dart:math' as math;

import 'scenario_mastery.dart';

/// Immutable snapshot of the player's progression stats.
///
/// Persisted as a single JSON string under the [storageKey] SharedPreferences
/// entry so the schema can evolve without migrations.
class UserStats {
  /// SharedPreferences key used by the service layer.
  static const storageKey = 'user_stats_v1';

  /// Consecutive days the player has played at least one hand or lesson.
  final int streakDays;

  /// Date of the most recent activity, stored as yyyy-mm-dd in UTC.
  /// Null when the player has never played.
  final DateTime? lastPlayedDay;

  /// Total lifetime XP earned.
  final int totalXp;

  /// Hands completed (any replay that reached isComplete).
  final int handsPlayed;

  /// Subset of [handsPlayed] where the viewer's hero seat won at showdown.
  final int handsWon;

  /// Lesson scenarios completed.
  final int lessonsCompleted;

  /// Highest streak the player has ever reached.
  final int bestStreakDays;

  /// Per-scenario mastery records keyed by `lessonId/scenarioIndex`.
  final Map<String, MasteryRecord> scenarioMastery;

  /// Achievement IDs the player has unlocked. Stored as the enum [name] so
  /// reordering is safe.
  final Set<String> unlockedAchievementIds;

  const UserStats({
    required this.streakDays,
    required this.lastPlayedDay,
    required this.totalXp,
    required this.handsPlayed,
    this.handsWon = 0,
    required this.lessonsCompleted,
    required this.bestStreakDays,
    this.scenarioMastery = const {},
    this.unlockedAchievementIds = const {},
  });

  /// Fresh stats for a brand-new install.
  const UserStats.empty()
      : streakDays = 0,
        lastPlayedDay = null,
        totalXp = 0,
        handsPlayed = 0,
        handsWon = 0,
        lessonsCompleted = 0,
        bestStreakDays = 0,
        scenarioMastery = const {},
        unlockedAchievementIds = const {};

  UserStats copyWith({
    int? streakDays,
    DateTime? lastPlayedDay,
    bool clearLastPlayedDay = false,
    int? totalXp,
    int? handsPlayed,
    int? handsWon,
    int? lessonsCompleted,
    int? bestStreakDays,
    Map<String, MasteryRecord>? scenarioMastery,
    Set<String>? unlockedAchievementIds,
  }) {
    return UserStats(
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDay: clearLastPlayedDay
          ? null
          : (lastPlayedDay ?? this.lastPlayedDay),
      totalXp: totalXp ?? this.totalXp,
      handsPlayed: handsPlayed ?? this.handsPlayed,
      handsWon: handsWon ?? this.handsWon,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      scenarioMastery: scenarioMastery ?? this.scenarioMastery,
      unlockedAchievementIds:
          unlockedAchievementIds ?? this.unlockedAchievementIds,
    );
  }

  /// Current level derived from [totalXp] via [Progression.levelForXp].
  int get level => Progression.levelForXp(totalXp);

  /// XP within the current level (0 .. xpForLevel(level+1) - xpForLevel(level) - 1).
  int get xpIntoLevel => totalXp - Progression.xpForLevel(level);

  /// XP required to complete the current level.
  int get xpNeededForNextLevel =>
      Progression.xpForLevel(level + 1) - Progression.xpForLevel(level);

  /// Progress through the current level in [0, 1].
  double get levelProgress {
    final span = xpNeededForNextLevel;
    if (span <= 0) return 0;
    return (xpIntoLevel / span).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    final masteryJson = <String, dynamic>{};
    scenarioMastery.forEach((k, v) => masteryJson[k] = v.toJson());
    return {
      'streakDays': streakDays,
      'lastPlayedDay': lastPlayedDay?.toIso8601String(),
      'totalXp': totalXp,
      'handsPlayed': handsPlayed,
      'handsWon': handsWon,
      'lessonsCompleted': lessonsCompleted,
      'bestStreakDays': bestStreakDays,
      if (masteryJson.isNotEmpty) 'mastery': masteryJson,
      if (unlockedAchievementIds.isNotEmpty)
        'unlocked': unlockedAchievementIds.toList(),
    };
  }

  String encode() => jsonEncode(toJson());

  static UserStats? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      // Mastery: tolerate missing/empty so legacy installs still load.
      final mastery = <String, MasteryRecord>{};
      final rawMastery = map['mastery'];
      if (rawMastery is Map) {
        rawMastery.forEach((k, v) {
          if (k is String && v is Map) {
            mastery[k] = MasteryRecord.fromJson(Map<String, dynamic>.from(v));
          }
        });
      }
      final unlocked = <String>{};
      final rawUnlocked = map['unlocked'];
      if (rawUnlocked is List) {
        for (final v in rawUnlocked) {
          if (v is String) unlocked.add(v);
        }
      }
      return UserStats(
        streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
        lastPlayedDay: map['lastPlayedDay'] is String
            ? DateTime.tryParse(map['lastPlayedDay'] as String)
            : null,
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        handsPlayed: (map['handsPlayed'] as num?)?.toInt() ?? 0,
        handsWon: (map['handsWon'] as num?)?.toInt() ?? 0,
        lessonsCompleted: (map['lessonsCompleted'] as num?)?.toInt() ?? 0,
        bestStreakDays: (map['bestStreakDays'] as num?)?.toInt() ?? 0,
        scenarioMastery: mastery,
        unlockedAchievementIds: unlocked,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Pure helpers for XP curves, level lookup, and streak rollover logic.
///
/// Kept free of Flutter/storage dependencies so it can be unit-tested in
/// isolation from IO.
abstract final class Progression {
  /// XP award for completing a single hand.
  static const xpPerHand = 10;

  /// Bonus XP when the viewer's controlled player wins at showdown.
  static const xpPerHandWin = 15;

  /// XP award for completing a lesson scenario.
  static const xpPerLesson = 50;

  /// One-time daily bonus granted when the streak counter ticks up.
  static const xpDailyBonus = 10;

  /// Bonus XP awarded the first time a player reaches a new star tier on
  /// a scenario (fires once per tier per scenario).
  static const xpPerStarTier = 25;

  /// Bonus XP awarded the first time an achievement is unlocked.
  static const xpPerAchievement = 50;

  /// Total XP required to reach [level] (level 0 = 0 XP, level 1 = 50 XP).
  ///
  /// Quadratic curve: xp(L) = 50 * L^2. Gentle early progression, steeper
  /// later. Level 1 @ 50, level 2 @ 200, level 3 @ 450, level 5 @ 1250.
  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    return 50 * level * level;
  }

  /// Level attained with [totalXp]. Inverse of [xpForLevel].
  static int levelForXp(int totalXp) {
    if (totalXp <= 0) return 0;
    return math.sqrt(totalXp / 50).floor();
  }

  /// Normalize a [DateTime] to a calendar-day key in the local zone.
  /// Used so "streak" rollover matches the user's perceived day boundary.
  static DateTime dayKey(DateTime ts) =>
      DateTime(ts.year, ts.month, ts.day);

  /// Apply a play event at [now] to [prev] and return the updated streak
  /// counter, the new last-played day, and any XP awarded for a daily bonus.
  ///
  /// Rules:
  /// - First play ever → streak = 1, award daily bonus.
  /// - Same calendar day as last play → streak unchanged, no bonus.
  /// - Exactly one day later → streak += 1, award daily bonus.
  /// - More than one day later → streak resets to 1, award daily bonus.
  static StreakResult applyActivity(UserStats prev, DateTime now) {
    final today = dayKey(now);
    final last = prev.lastPlayedDay;
    if (last == null) {
      return StreakResult(
        newStreakDays: 1,
        newLastPlayedDay: today,
        dailyBonusXp: xpDailyBonus,
      );
    }
    final lastDay = dayKey(last);
    final delta = today.difference(lastDay).inDays;
    if (delta == 0) {
      return StreakResult(
        newStreakDays: prev.streakDays == 0 ? 1 : prev.streakDays,
        newLastPlayedDay: lastDay,
        dailyBonusXp: 0,
      );
    }
    if (delta == 1) {
      return StreakResult(
        newStreakDays: prev.streakDays + 1,
        newLastPlayedDay: today,
        dailyBonusXp: xpDailyBonus,
      );
    }
    // Gap > 1 day: streak broken, restart at 1.
    return StreakResult(
      newStreakDays: 1,
      newLastPlayedDay: today,
      dailyBonusXp: xpDailyBonus,
    );
  }
}

/// Outcome of applying a play event to a prior [UserStats].
class StreakResult {
  final int newStreakDays;
  final DateTime newLastPlayedDay;
  final int dailyBonusXp;

  const StreakResult({
    required this.newStreakDays,
    required this.newLastPlayedDay,
    required this.dailyBonusXp,
  });
}
