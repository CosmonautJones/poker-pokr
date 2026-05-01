import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement.dart';
import 'achievements_catalog.dart';
import 'unlocked_achievements.dart';
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

  /// Reset progression to a fresh install. Also clears unlocks + toast queue.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
    await ref.read(unlockedAchievementsProvider.notifier).reset();
    ref.read(pendingAchievementToastsProvider.notifier).clear();
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
    await _evaluateAchievements(updated, now);
  }

  /// Evaluate the catalog against [stats] and unlock anything new.
  /// [at] is used as the unlock timestamp so callers can keep tests
  /// deterministic by passing a fixed `DateTime`.
  Future<void> _evaluateAchievements(UserStats stats, DateTime at) async {
    final unlocksNotifier =
        ref.read(unlockedAchievementsProvider.notifier);
    final unlocks = ref.read(unlockedAchievementsProvider);
    final newlyUnlocked = <Achievement>[];
    for (final a in AchievementsCatalog.all) {
      if (unlocks.contains(a.id)) continue;
      if (a.test(stats)) newlyUnlocked.add(a);
    }
    if (newlyUnlocked.isEmpty) return;
    await unlocksNotifier.unlockMany(newlyUnlocked.map((a) => a.id), at);
    ref
        .read(pendingAchievementToastsProvider.notifier)
        .enqueueAll(newlyUnlocked);
  }
}

/// Persisted set of unlocked achievement ids.
final unlockedAchievementsProvider =
    NotifierProvider<UnlockedAchievementsNotifier, UnlockedAchievements>(
  UnlockedAchievementsNotifier.new,
);

/// FIFO queue of achievements waiting to be shown by the toast overlay.
///
/// The UI dequeues by calling [PendingAchievementToastsNotifier.dismissCurrent]
/// after it has displayed the head item.
final pendingAchievementToastsProvider = NotifierProvider<
    PendingAchievementToastsNotifier, List<Achievement>>(
  PendingAchievementToastsNotifier.new,
);

class UnlockedAchievementsNotifier extends Notifier<UnlockedAchievements> {
  @override
  UnlockedAchievements build() =>
      ref.read(userStatsServiceProvider).loadUnlocks();

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  Future<void> unlock(String id, DateTime at) async {
    if (state.contains(id)) return;
    state = state.copyWithUnlock(id, at);
    await _service.saveUnlocks(state);
  }

  /// Bulk variant; persists once after all ids are merged.
  Future<void> unlockMany(Iterable<String> ids, DateTime at) async {
    var next = state;
    for (final id in ids) {
      next = next.copyWithUnlock(id, at);
    }
    if (identical(next, state)) return;
    state = next;
    await _service.saveUnlocks(state);
  }

  Future<void> reset() async {
    state = const UnlockedAchievements.empty();
    await _service.saveUnlocks(state);
  }
}

class PendingAchievementToastsNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => const [];

  void enqueueAll(Iterable<Achievement> items) {
    if (items.isEmpty) return;
    state = [...state, ...items];
  }

  /// Pops the head item; call after the UI finishes showing it.
  void dismissCurrent() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  void clear() {
    state = const [];
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
