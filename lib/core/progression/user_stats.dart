import 'dart:convert';
import 'dart:math' as math;

/// Immutable snapshot of the player's progression stats.
///
/// Persisted as a single JSON string under the [storageKey] SharedPreferences
/// entry so the schema can evolve without migrations.
class UserStats {
  /// SharedPreferences key used by the service layer.
  static const storageKey = 'user_stats_v1';

  /// Sentinel for "no big hand seen yet". Stored alongside HandRank indices
  /// (0..8) so any non-negative value compares meaningfully.
  static const int noBestHand = -1;

  /// Consecutive days the player has played at least one hand or lesson.
  final int streakDays;

  /// Date of the most recent activity, stored as yyyy-mm-dd in UTC.
  /// Null when the player has never played.
  final DateTime? lastPlayedDay;

  /// Total lifetime XP earned.
  final int totalXp;

  /// Hands completed (any replay that reached isComplete).
  final int handsPlayed;

  /// Hands the viewer's controlled player has won.
  final int handsWon;

  /// Highest poker.engine.HandRank index the viewer has held at showdown.
  /// `-1` means no showdown has happened yet (or never reached one).
  final int bestHandRankIndex;

  /// Lesson scenarios completed.
  final int lessonsCompleted;

  /// Highest streak the player has ever reached.
  final int bestStreakDays;

  /// Stable ids of achievements that have been unlocked.
  /// Stored as a sorted list for deterministic JSON.
  final Set<String> unlockedAchievementIds;

  const UserStats({
    required this.streakDays,
    required this.lastPlayedDay,
    required this.totalXp,
    required this.handsPlayed,
    required this.handsWon,
    required this.bestHandRankIndex,
    required this.lessonsCompleted,
    required this.bestStreakDays,
    required this.unlockedAchievementIds,
  });

  /// Fresh stats for a brand-new install.
  const UserStats.empty()
      : streakDays = 0,
        lastPlayedDay = null,
        totalXp = 0,
        handsPlayed = 0,
        handsWon = 0,
        bestHandRankIndex = noBestHand,
        lessonsCompleted = 0,
        bestStreakDays = 0,
        unlockedAchievementIds = const <String>{};

  UserStats copyWith({
    int? streakDays,
    DateTime? lastPlayedDay,
    bool clearLastPlayedDay = false,
    int? totalXp,
    int? handsPlayed,
    int? handsWon,
    int? bestHandRankIndex,
    int? lessonsCompleted,
    int? bestStreakDays,
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
      bestHandRankIndex: bestHandRankIndex ?? this.bestHandRankIndex,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      bestStreakDays: bestStreakDays ?? this.bestStreakDays,
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

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'lastPlayedDay': lastPlayedDay?.toIso8601String(),
        'totalXp': totalXp,
        'handsPlayed': handsPlayed,
        'handsWon': handsWon,
        'bestHandRankIndex': bestHandRankIndex,
        'lessonsCompleted': lessonsCompleted,
        'bestStreakDays': bestStreakDays,
        'unlockedAchievementIds': (unlockedAchievementIds.toList()..sort()),
      };

  String encode() => jsonEncode(toJson());

  static UserStats? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final ids = map['unlockedAchievementIds'];
      final unlocked = <String>{
        if (ids is List)
          for (final v in ids)
            if (v is String) v,
      };
      return UserStats(
        streakDays: (map['streakDays'] as num?)?.toInt() ?? 0,
        lastPlayedDay: map['lastPlayedDay'] is String
            ? DateTime.tryParse(map['lastPlayedDay'] as String)
            : null,
        totalXp: (map['totalXp'] as num?)?.toInt() ?? 0,
        handsPlayed: (map['handsPlayed'] as num?)?.toInt() ?? 0,
        handsWon: (map['handsWon'] as num?)?.toInt() ?? 0,
        bestHandRankIndex:
            (map['bestHandRankIndex'] as num?)?.toInt() ?? noBestHand,
        lessonsCompleted: (map['lessonsCompleted'] as num?)?.toInt() ?? 0,
        bestStreakDays: (map['bestStreakDays'] as num?)?.toInt() ?? 0,
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

  /// XP awarded the first time an achievement unlocks.
  static const xpPerAchievement = 25;

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
