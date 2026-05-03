import 'dart:convert';
import 'dart:math' as math;

/// Immutable snapshot of the player's progression stats.
///
/// Persisted as a single JSON string under the [storageKey] SharedPreferences
/// entry so the schema can evolve without migrations. Newly added fields use
/// safe defaults inside [tryDecode] so older payloads decode cleanly.
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

  /// Lesson scenarios completed.
  final int lessonsCompleted;

  /// Highest streak the player has ever reached.
  final int bestStreakDays;

  /// Lifetime showdown wins by the viewer's hero seat.
  final int lifetimeWins;

  /// Set of achievement ids the player has unlocked. Order preserved on
  /// disk for stable display in the profile grid (most-recently unlocked
  /// last so we can render newest-first when desired).
  final List<String> unlockedAchievements;

  /// Most recent calendar day the player completed the daily challenge.
  /// Null until the first daily challenge is finished.
  final DateTime? dailyChallengeLastCompletedDay;

  /// Lifetime count of daily challenges completed.
  final int dailyChallengesCompleted;

  const UserStats({
    required this.streakDays,
    required this.lastPlayedDay,
    required this.totalXp,
    required this.handsPlayed,
    required this.lessonsCompleted,
    required this.bestStreakDays,
    this.lifetimeWins = 0,
    this.unlockedAchievements = const <String>[],
    this.dailyChallengeLastCompletedDay,
    this.dailyChallengesCompleted = 0,
  });

  /// Fresh stats for a brand-new install.
  const UserStats.empty()
      : streakDays = 0,
        lastPlayedDay = null,
        totalXp = 0,
        handsPlayed = 0,
        lessonsCompleted = 0,
        bestStreakDays = 0,
        lifetimeWins = 0,
        unlockedAchievements = const <String>[],
        dailyChallengeLastCompletedDay = null,
        dailyChallengesCompleted = 0;

  UserStats copyWith({
    int? streakDays,
    DateTime? lastPlayedDay,
    bool clearLastPlayedDay = false,
    int? totalXp,
    int? handsPlayed,
    int? lessonsCompleted,
    int? bestStreakDays,
    int? lifetimeWins,
    List<String>? unlockedAchievements,
    DateTime? dailyChallengeLastCompletedDay,
    bool clearDailyChallengeLastCompletedDay = false,
    int? dailyChallengesCompleted,
  }) {
    return UserStats(
      streakDays: streakDays ?? this.streakDays,
      lastPlayedDay: clearLastPlayedDay
          ? null
          : (lastPlayedDay ?? this.lastPlayedDay),
      totalXp: totalXp ?? this.totalXp,
      handsPlayed: handsPlayed ?? this.handsPlayed,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
      lifetimeWins: lifetimeWins ?? this.lifetimeWins,
      unlockedAchievements:
          unlockedAchievements ?? this.unlockedAchievements,
      dailyChallengeLastCompletedDay: clearDailyChallengeLastCompletedDay
          ? null
          : (dailyChallengeLastCompletedDay ??
              this.dailyChallengeLastCompletedDay),
      dailyChallengesCompleted:
          dailyChallengesCompleted ?? this.dailyChallengesCompleted,
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

  /// True if the daily challenge for [now] has already been completed.
  bool dailyChallengeDoneOn(DateTime now) {
    final last = dailyChallengeLastCompletedDay;
    if (last == null) return false;
    return Progression.dayKey(last) == Progression.dayKey(now);
  }

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'lastPlayedDay': lastPlayedDay?.toIso8601String(),
        'totalXp': totalXp,
        'handsPlayed': handsPlayed,
        'lessonsCompleted': lessonsCompleted,
        'bestStreakDays': bestStreakDays,
        'lifetimeWins': lifetimeWins,
        'unlockedAchievements': unlockedAchievements,
        'dailyChallengeLastCompletedDay':
            dailyChallengeLastCompletedDay?.toIso8601String(),
        'dailyChallengesCompleted': dailyChallengesCompleted,
      };

  String encode() => jsonEncode(toJson());

  static UserStats? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserStats(
        streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
        lastPlayedDay: map['lastPlayedDay'] is String
            ? DateTime.tryParse(map['lastPlayedDay'] as String)
            : null,
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        handsPlayed: (map['handsPlayed'] as num?)?.toInt() ?? 0,
        lessonsCompleted: (map['lessonsCompleted'] as num?)?.toInt() ?? 0,
        bestStreakDays: (map['bestStreakDays'] as num?)?.toInt() ?? 0,
        lifetimeWins: (map['lifetimeWins'] as num?)?.toInt() ?? 0,
        unlockedAchievements: (map['unlockedAchievements'] as List?)
                ?.whereType<String>()
                .toList(growable: false) ??
            const <String>[],
        dailyChallengeLastCompletedDay:
            map['dailyChallengeLastCompletedDay'] is String
                ? DateTime.tryParse(
                    map['dailyChallengeLastCompletedDay'] as String)
                : null,
        dailyChallengesCompleted:
            (map['dailyChallengesCompleted'] as num?)?.toInt() ?? 0,
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

  /// Bonus XP awarded the first time the daily challenge is completed each day.
  static const xpDailyChallengeBonus = 30;

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
