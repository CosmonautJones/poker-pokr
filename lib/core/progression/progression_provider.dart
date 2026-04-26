import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement_state.dart';
import 'achievements.dart';
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

/// Persisted map of unlocked achievements (id → unlockedAt timestamp).
final achievementStateProvider =
    NotifierProvider<AchievementStateNotifier, AchievementState>(
  AchievementStateNotifier.new,
);

/// Ephemeral queue of achievements unlocked during the current run.
///
/// Pushed to by [UserStatsNotifier] after a stat change and consumed by the
/// celebration overlay; not persisted across launches.
final recentlyUnlockedAchievementsProvider =
    NotifierProvider<RecentUnlocksNotifier, List<Achievement>>(
  RecentUnlocksNotifier.new,
);

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
    );
  }

  /// Reset progression to a fresh install. Also clears unlocked achievements.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
    await ref.read(achievementStateProvider.notifier).clear();
    ref.read(recentlyUnlockedAchievementsProvider.notifier).clear();
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
    await _detectNewUnlocks(updated);
  }

  Future<void> _detectNewUnlocks(UserStats updated) async {
    final achievementsNotifier =
        ref.read(achievementStateProvider.notifier);
    final current = ref.read(achievementStateProvider);
    final unlockedIds = Achievement.evaluateAll(updated);
    final now = DateTime.now();
    final newUnlocks = <String, DateTime>{};
    for (final id in unlockedIds) {
      if (!current.isUnlocked(id)) {
        newUnlocks[id] = now;
      }
    }
    if (newUnlocks.isEmpty) return;
    await achievementsNotifier.addUnlocks(newUnlocks);
    final recent = ref.read(recentlyUnlockedAchievementsProvider.notifier);
    for (final id in newUnlocks.keys) {
      final achievement = Achievement.byId(id);
      if (achievement != null) recent.push(achievement);
    }
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

class AchievementStateNotifier extends Notifier<AchievementState> {
  @override
  AchievementState build() =>
      ref.read(userStatsServiceProvider).loadAchievements();

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  Future<void> addUnlocks(Map<String, DateTime> additions) async {
    final next = state.copyWithNewUnlocks(additions);
    if (identical(next, state)) return;
    state = next;
    await _service.saveAchievements(next);
  }

  Future<void> clear() async {
    state = const AchievementState.empty();
    await _service.saveAchievements(state);
  }
}

class RecentUnlocksNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => const [];

  void push(Achievement a) {
    if (state.any((e) => e.id == a.id)) return;
    state = [...state, a];
  }

  void popFirst() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}
