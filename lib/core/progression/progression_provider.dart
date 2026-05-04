import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement.dart';
import 'achievements_catalog.dart';
import 'achievements_provider.dart';
import 'user_stats.dart';
import 'user_stats_service.dart';

/// Singleton provider for the SharedPreferences-backed service.
///
/// Overridden in `main()` with a concrete instance once SharedPreferences
/// has been initialized; also overridden in tests with an in-memory stub.
final userStatsServiceProvider = Provider<UserStatsService>((ref) {
  throw UnimplementedError(
    'userStatsServiceProvider must be overridden with a UserStatsService '
    'instance (see main.dart).',
  );
});

/// Live user stats snapshot. Rebuilds when [recordHandPlayed] /
/// [recordLessonComplete] / [resetAll] mutate state.
final userStatsProvider =
    NotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

/// Haptics preference toggle. Writes through to SharedPreferences.
final hapticsEnabledProvider =
    NotifierProvider<HapticsPrefNotifier, bool>(HapticsPrefNotifier.new);

class UserStatsNotifier extends Notifier<UserStats> {
  @override
  UserStats build() => ref.read(userStatsServiceProvider).loadStats();

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  /// Award XP for finishing a hand.
  ///
  /// [playerWon] granted bonus XP when the viewer's player is among winners,
  /// and increments the persisted `handsWon` counter (which feeds the
  /// showdown achievements).
  Future<void> recordHandPlayed({
    bool playerWon = false,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final baseXp = Progression.xpPerHand +
        (playerWon ? Progression.xpPerHandWin : 0) +
        streak.dailyBonusXp;
    await _apply(
      prev: prev,
      streak: streak,
      xpDelta: baseXp,
      handsDelta: 1,
      lessonsDelta: 0,
      handsWonDelta: playerWon ? 1 : 0,
    );
  }

  /// Award XP for completing a lesson scenario.
  Future<void> recordLessonComplete({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final xp = Progression.xpPerLesson + streak.dailyBonusXp;
    await _apply(
      prev: prev,
      streak: streak,
      xpDelta: xp,
      handsDelta: 0,
      lessonsDelta: 1,
      handsWonDelta: 0,
    );
  }

  /// Reset progression to a fresh install. Also clears the achievements
  /// unlock set so the player can re-experience the celebrations.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
    await ref.read(achievementsProvider.notifier).reset();
    ref.read(newlyUnlockedProvider.notifier).state = const [];
  }

  Future<void> _apply({
    required UserStats prev,
    required StreakResult streak,
    required int xpDelta,
    required int handsDelta,
    required int lessonsDelta,
    required int handsWonDelta,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;

    final updated = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
      handsWon: prev.handsWon + handsWonDelta,
    );
    state = updated;
    await _service.saveStats(updated);
    await _evaluateAchievements(updated);
  }

  /// Evaluate the achievement catalog against the post-mutation [stats] and
  /// queue any newly-earned IDs onto [newlyUnlockedProvider] so the UI
  /// overlay can play a celebration. Existing unlocks are skipped.
  Future<void> _evaluateAchievements(UserStats stats) async {
    final earnedNow = currentlyEarned(stats);
    if (earnedNow.isEmpty) return;
    final fresh =
        await ref.read(achievementsProvider.notifier).markEarned(earnedNow);
    if (fresh.isEmpty) return;
    final queue = ref.read(newlyUnlockedProvider.notifier);
    queue.state = [...queue.state, ...fresh];
  }
}

class HapticsPrefNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(userStatsServiceProvider).loadHapticsEnabled();

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref.read(userStatsServiceProvider).saveHapticsEnabled(enabled);
  }
}
