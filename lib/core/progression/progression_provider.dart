import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation_keys.dart';
import 'achievements.dart';
import 'achievements_provider.dart';
import 'daily_challenges.dart';
import 'daily_challenges_provider.dart';
import 'unlock_toast.dart';
import 'user_stats.dart';
import 'user_stats_service.dart';

/// Spacing between consecutive toasts so multiple unlocks stack visibly
/// instead of replacing each other instantly.
const _toastStagger = Duration(milliseconds: 250);

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
  /// [playerWon] grants bonus XP when the viewer's player is among winners.
  /// [achievementContext] is forwarded to the achievement engine so we can
  /// score outcomes (showdown win, nuts, river equity) that aren't reflected
  /// in [UserStats] alone. Also nudges any matching daily challenges.
  Future<void> recordHandPlayed({
    bool playerWon = false,
    DateTime? now,
    AchievementContext? achievementContext,
    bool reachedShowdown = false,
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
    );
    await _evaluateAchievements(achievementContext, now: ts);
    await _bumpHandChallenges(
      reachedShowdown: reachedShowdown,
      wonShowdown: playerWon && reachedShowdown,
      now: ts,
    );
  }

  /// Award XP for completing a lesson scenario.
  Future<void> recordLessonComplete({
    DateTime? now,
    AchievementContext? achievementContext,
  }) async {
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
    );
    await _evaluateAchievements(achievementContext, now: ts);
    await _nudgeChallenge('lesson_1', 1);
  }

  /// XP-only award path used by daily-challenge completion (no streak bump,
  /// no hand/lesson counter mutation). Persists immediately.
  Future<void> awardChallengeXp(int xp, {DateTime? now}) async {
    if (xp <= 0) return;
    final updated = state.copyWith(totalXp: state.totalXp + xp);
    state = updated;
    await _service.saveStats(updated);
  }

  Future<void> _evaluateAchievements(
    AchievementContext? ctx, {
    required DateTime now,
  }) async {
    // Achievements provider is optional in tests that don't override it; tests
    // that exercise the achievement path must provide the override.
    final notifier = _achievementsNotifierOrNull();
    if (notifier == null) return;
    final unlocked = await notifier.evaluate(state, ctx: ctx, now: now);
    if (unlocked.isNotEmpty) {
      // Fire-and-forget: notifiers don't have a BuildContext, so we route
      // toasts through the root navigator key. Failure to surface is silent.
      unawaited(_surfaceUnlockedAchievements(unlocked));
    }
  }

  Future<void> _surfaceUnlockedAchievements(
    List<Achievement> unlocked,
  ) async {
    for (var i = 0; i < unlocked.length; i++) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) return; // App shutting down or not yet mounted.
      final def = Achievements.byId(unlocked[i].definitionId);
      if (def == null) continue;
      showAchievementUnlocked(ctx, def);
      if (i < unlocked.length - 1) {
        await Future<void>.delayed(_toastStagger);
      }
    }
  }

  AchievementsNotifier? _achievementsNotifierOrNull() {
    try {
      return ref.read(achievementsProvider.notifier);
    } catch (_) {
      return null;
    }
  }

  Future<void> _bumpHandChallenges({
    required bool reachedShowdown,
    required bool wonShowdown,
    required DateTime now,
  }) async {
    await _nudgeChallenge('play_3', 1);
    await _nudgeChallenge('play_5', 1);
    if (reachedShowdown) {
      await _nudgeChallenge('showdown_1', 1);
    }
    if (wonShowdown) {
      await _nudgeChallenge('win_1', 1);
    }
  }

  Future<void> _nudgeChallenge(String id, int amount) async {
    final notifier = _challengesNotifierOrNull();
    if (notifier == null) return;
    final justCompleted = await notifier.incrementProgress(id, amount);
    if (justCompleted == null) return;
    final def = DailyChallenges.byId(justCompleted.definitionId);
    if (def == null) return;
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    showChallengeCompleted(ctx, def, def.xpReward);
  }

  DailyChallengesNotifier? _challengesNotifierOrNull() {
    try {
      return ref.read(dailyChallengesProvider.notifier);
    } catch (_) {
      return null;
    }
  }

  /// Reset progression to a fresh install.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
  }

  Future<void> _apply({
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
