import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements/achievement.dart';
import 'achievements/achievement_event.dart';
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

  /// Award XP for finishing a hand and dispatch the corresponding achievement
  /// + daily-challenge event. The result of unlocks/completions is published
  /// to [lastDispatchResultProvider] for the UI to celebrate.
  Future<void> recordHandPlayed({
    bool playerWon = false,
    HandCompletedEvent? event,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final baseXp = Progression.xpPerHand +
        (playerWon ? Progression.xpPerHandWin : 0) +
        streak.dailyBonusXp;
    final nextStats = await _apply(
      prev: prev,
      streak: streak,
      xpDelta: baseXp,
      handsDelta: 1,
      lessonsDelta: 0,
    );
    await _dispatchPlayEvents(
      prev: prev,
      next: nextStats,
      streak: streak,
      handEvent: event,
      now: ts,
    );
  }

  /// Award XP for completing a lesson scenario.
  Future<void> recordLessonComplete({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final xp = Progression.xpPerLesson + streak.dailyBonusXp;
    final nextStats = await _apply(
      prev: prev,
      streak: streak,
      xpDelta: xp,
      handsDelta: 0,
      lessonsDelta: 1,
    );
    await _dispatchPlayEvents(
      prev: prev,
      next: nextStats,
      streak: streak,
      handEvent: null,
      lessonEvent: const LessonCompletedEvent(),
      now: ts,
    );
  }

  /// Reset progression to a fresh install. Also clears achievements + daily
  /// challenge so the user starts from zero everywhere.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
    await ref.read(achievementsProvider.notifier).resetAll();
    await ref.read(dailyChallengeProvider.notifier).resetForToday();
    ref.read(lastDispatchResultProvider.notifier).clear();
  }

  /// Add XP to the lifetime total without touching streak / counters. Called
  /// by the achievements layer when an unlock or daily-claim grants XP so
  /// those rewards roll up into the same level curve.
  ///
  /// If the new XP crosses a level boundary, a [LevelReachedEvent] is fanned
  /// out so level-based achievements (level_5, level_10) can unlock from XP
  /// rewards alone. Any cascaded unlocks are merged into
  /// [lastDispatchResultProvider] so the celebration banner still fires.
  Future<void> awardXpForAchievements(int xp) async {
    if (xp <= 0) return;
    final prev = state;
    final updated = prev.copyWith(totalXp: prev.totalXp + xp);
    state = updated;
    await _service.saveStats(updated);
    if (updated.level > prev.level) {
      final cascade = await ref
          .read(achievementsProvider.notifier)
          .dispatch(LevelReachedEvent(updated.level));
      if (cascade.isNotEmpty) {
        _mergeIntoLastDispatch(unlocked: cascade);
      }
    }
  }

  void _mergeIntoLastDispatch({
    List<Achievement> unlocked = const [],
    bool dailyJustCompleted = false,
  }) {
    if (unlocked.isEmpty && !dailyJustCompleted) return;
    final notifier = ref.read(lastDispatchResultProvider.notifier);
    final prior = ref.read(lastDispatchResultProvider);
    notifier.set(
      AchievementDispatchResult(
        newlyUnlocked: List.unmodifiable(
          [...prior.newlyUnlocked, ...unlocked],
        ),
        dailyJustCompleted:
            prior.dailyJustCompleted || dailyJustCompleted,
      ),
    );
  }

  Future<UserStats> _apply({
    required UserStats prev,
    required StreakResult streak,
    required int xpDelta,
    required int handsDelta,
    required int lessonsDelta,
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
    );
    state = updated;
    await _service.saveStats(updated);
    return updated;
  }

  /// Dispatch the cluster of events that follow a play activity:
  ///   hand/lesson event → streak (if it stepped up) → level (if it stepped up)
  /// Each is sent through both the achievements + daily challenge channels.
  /// Newly-unlocked achievements + a daily-completion flag are surfaced via
  /// [lastDispatchResultProvider].
  Future<void> _dispatchPlayEvents({
    required UserStats prev,
    required UserStats next,
    required StreakResult streak,
    HandCompletedEvent? handEvent,
    LessonCompletedEvent? lessonEvent,
    required DateTime now,
  }) async {
    final achievements = ref.read(achievementsProvider.notifier);
    final daily = ref.read(dailyChallengeProvider.notifier);

    final unlocked = <Achievement>[];
    var dailyJustCompleted = false;

    Future<void> sendOne(AchievementEvent ev) async {
      final newly = await achievements.dispatch(ev, now: now);
      unlocked.addAll(newly);
      final completed = await daily.dispatch(ev, now: now);
      if (completed) dailyJustCompleted = true;
    }

    if (handEvent != null) await sendOne(handEvent);
    if (lessonEvent != null) await sendOne(lessonEvent);

    // Streak event fires only when the streak counter actually advanced.
    if (streak.newStreakDays > prev.streakDays) {
      await sendOne(StreakAdvancedEvent(streak.newStreakDays));
    }

    // Level event fires only when level crossed a boundary.
    if (next.level > prev.level) {
      await sendOne(LevelReachedEvent(next.level));
    }

    _mergeIntoLastDispatch(
      unlocked: unlocked,
      dailyJustCompleted: dailyJustCompleted,
    );
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
