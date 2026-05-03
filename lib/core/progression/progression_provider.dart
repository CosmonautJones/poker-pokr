import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'daily_challenge.dart';
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

/// Most-recent batch of newly-unlocked achievement ids from the latest
/// progression mutation. Cleared by UI consumers via [popUnlocks] once the
/// celebration toast has been shown so it doesn't fire twice on rebuilds.
final pendingUnlocksProvider =
    NotifierProvider<PendingUnlocksNotifier, List<String>>(
  PendingUnlocksNotifier.new,
);

class UserStatsNotifier extends Notifier<UserStats> {
  @override
  UserStats build() => ref.read(userStatsServiceProvider).loadStats();

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  /// Award XP for finishing a hand. Returns ids of any achievements
  /// newly unlocked by this event so the caller can trigger a toast.
  ///
  /// [playerWon] grants bonus XP and bumps lifetimeWins when true.
  Future<List<String>> recordHandPlayed({
    bool playerWon = false,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final baseXp = Progression.xpPerHand +
        (playerWon ? Progression.xpPerHandWin : 0) +
        streak.dailyBonusXp;
    return _apply(
      prev: prev,
      streak: streak,
      xpDelta: baseXp,
      handsDelta: 1,
      lessonsDelta: 0,
      winsDelta: playerWon ? 1 : 0,
    );
  }

  /// Award XP for completing a lesson scenario. Returns newly-unlocked ids.
  Future<List<String>> recordLessonComplete({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final xp = Progression.xpPerLesson + streak.dailyBonusXp;
    return _apply(
      prev: prev,
      streak: streak,
      xpDelta: xp,
      handsDelta: 0,
      lessonsDelta: 1,
      winsDelta: 0,
    );
  }

  /// If [lessonId]/[scenarioIndex] matches today's daily challenge AND it
  /// hasn't already been recorded today, mark it done and award the bonus.
  /// Returns newly-unlocked achievement ids from this single mutation.
  ///
  /// Idempotent: a second call on the same day is a no-op.
  Future<List<String>> recordDailyChallengeIfMatch({
    required String lessonId,
    required int scenarioIndex,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final today = challengeFor(ts);
    if (today == null) return const <String>[];
    if (today.lessonId != lessonId ||
        today.scenarioIndex != scenarioIndex) {
      return const <String>[];
    }
    final prev = state;
    if (prev.dailyChallengeDoneOn(ts)) return const <String>[];
    // Daily challenge counts as activity. Run it through the streak engine
    // so the same calendar day collapses to no extra streak bonus, while
    // also covering the (unlikely) edge case where the challenge is the
    // user's only activity of the day.
    final streak = Progression.applyActivity(prev, ts);
    final xp =
        Progression.xpDailyChallengeBonus + streak.dailyBonusXp;
    final unlocked = await _apply(
      prev: prev,
      streak: streak,
      xpDelta: xp,
      handsDelta: 0,
      lessonsDelta: 0,
      winsDelta: 0,
      markDailyChallengeDay: Progression.dayKey(ts),
      dailyChallengesDelta: 1,
    );
    return unlocked;
  }

  /// Reset progression to a fresh install.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
  }

  /// Apply a delta to [state] and persist. Returns ids that were newly
  /// unlocked by this transition (subset of catalog, in catalog order).
  Future<List<String>> _apply({
    required UserStats prev,
    required StreakResult streak,
    required int xpDelta,
    required int handsDelta,
    required int lessonsDelta,
    required int winsDelta,
    DateTime? markDailyChallengeDay,
    int dailyChallengesDelta = 0,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;

    // Merge previous unlocks with anything newly satisfied by the post-
    // mutation snapshot. We preserve the prior order and append new ids
    // so the achievement grid renders earned-first stably.
    final tentative = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
      lifetimeWins: prev.lifetimeWins + winsDelta,
      dailyChallengeLastCompletedDay: markDailyChallengeDay,
      dailyChallengesCompleted:
          prev.dailyChallengesCompleted + dailyChallengesDelta,
    );

    final earned = evaluateUnlockedIds(tentative);
    final newIds = newlyUnlocked(prev.unlockedAchievements, earned);
    final merged = <String>[
      ...prev.unlockedAchievements.where((id) {
        // Drop any ids that no longer match the catalog (e.g. retired).
        return findAchievementById(id) != null;
      }),
      ...newIds,
    ];

    final updated = tentative.copyWith(unlockedAchievements: merged);
    state = updated;
    await _service.saveStats(updated);

    if (newIds.isNotEmpty) {
      ref.read(pendingUnlocksProvider.notifier).push(newIds);
    }
    return newIds;
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

/// Queue-style notifier for achievement unlock events. The trainer screens
/// drain it via [popUnlocks] after showing the celebration toast.
class PendingUnlocksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const <String>[];

  void push(List<String> ids) {
    if (ids.isEmpty) return;
    state = [...state, ...ids];
  }

  /// Returns and clears all queued ids. Idempotent — a follow-up call on
  /// the same frame returns an empty list.
  List<String> popAll() {
    if (state.isEmpty) return const <String>[];
    final out = state;
    state = const <String>[];
    return out;
  }
}
