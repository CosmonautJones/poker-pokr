import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement.dart';
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

/// Queue of achievements that unlocked but haven't been presented to the user
/// yet. The UI layer pops the head on a timer / after its toast animates out.
/// State is intentionally transient — never persisted.
final pendingAchievementUnlocksProvider = NotifierProvider<
    PendingAchievementUnlocksNotifier, List<String>>(
  PendingAchievementUnlocksNotifier.new,
);

class UserStatsNotifier extends Notifier<UserStats> {
  @override
  UserStats build() {
    final loaded = ref.read(userStatsServiceProvider).loadStats();
    // One-time silent backfill: users who already had progression from
    // before this feature shipped get their due badges recorded without
    // generating a flood of toasts on first launch.
    if (loaded.unlockedAchievements.isEmpty && _hasAnyProgress(loaded)) {
      final backfilled = _silentlyBackfill(loaded);
      // Fire-and-forget; state value starts from the backfilled snapshot.
      unawaited(ref.read(userStatsServiceProvider).saveStats(backfilled));
      return backfilled;
    }
    return loaded;
  }

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  /// Award XP for finishing a hand.
  ///
  /// [playerWon] granted bonus XP when the viewer's player is among winners.
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
      now: ts,
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
      now: ts,
    );
  }

  /// Reset progression to a fresh install.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    ref.read(pendingAchievementUnlocksProvider.notifier).clear();
    await _service.saveStats(state);
  }

  Future<void> _apply({
    required UserStats prev,
    required StreakResult streak,
    required int xpDelta,
    required int handsDelta,
    required int lessonsDelta,
    required DateTime now,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;

    final preUnlock = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
    );

    final newlyUnlocked = AchievementEvaluator.newlyUnlocked(
      prev: prev,
      next: preUnlock,
    );

    final updated = newlyUnlocked.isEmpty
        ? preUnlock
        : preUnlock.copyWith(
            unlockedAchievements: {
              ...preUnlock.unlockedAchievements,
              for (final id in newlyUnlocked) id: now,
            },
          );

    state = updated;
    await _service.saveStats(updated);

    if (newlyUnlocked.isNotEmpty) {
      ref
          .read(pendingAchievementUnlocksProvider.notifier)
          .enqueueAll(newlyUnlocked);
    }
  }

  static bool _hasAnyProgress(UserStats s) =>
      s.totalXp > 0 ||
      s.handsPlayed > 0 ||
      s.lessonsCompleted > 0 ||
      s.bestStreakDays > 0;

  /// Compute satisfied badges for an existing player and stamp them all
  /// with the [lastPlayedDay] (or current install time as a fallback) so the
  /// achievements grid shows reasonable "unlocked" timestamps instead of all
  /// clustered at literal now-time.
  static UserStats _silentlyBackfill(UserStats s) {
    final satisfied = AchievementEvaluator.satisfiedIds(s);
    if (satisfied.isEmpty) return s;
    final ts = s.lastPlayedDay ?? DateTime.now();
    return s.copyWith(
      unlockedAchievements: {
        for (final id in satisfied) id: ts,
      },
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

/// FIFO queue of pending achievement unlocks.
///
/// The producer (progression notifier) appends ids as they unlock; the
/// consumer (UI overlay) pops the head after each toast finishes animating.
/// State is deliberately transient so a queue doesn't leak across sessions.
class PendingAchievementUnlocksNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void enqueueAll(Iterable<String> ids) {
    if (ids.isEmpty) return;
    state = [...state, ...ids];
  }

  /// Pops the head of the queue if any. Returns the id or null.
  String? popNext() {
    if (state.isEmpty) return null;
    final head = state.first;
    state = state.sublist(1);
    return head;
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}
