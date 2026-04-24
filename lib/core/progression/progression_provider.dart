import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement.dart';
import 'achievements_catalog.dart';
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

/// Broadcast stream of achievements that transitioned to unlocked as a
/// result of the most recent stat change. Emits one [Achievement] per
/// unlock. Consumed by the global toast overlay.
///
/// Using a broadcast stream — rather than a Riverpod state field — lets
/// listeners react to transient unlock *events* without coupling to the
/// persisted [UserStats] snapshot. Late subscribers don't replay past
/// unlocks, which is the right behavior for toast notifications.
final achievementUnlocksProvider = Provider<Stream<Achievement>>(
  (ref) => ref.read(userStatsProvider.notifier).unlockStream,
);

class UserStatsNotifier extends Notifier<UserStats> {
  final StreamController<Achievement> _unlocks =
      StreamController<Achievement>.broadcast();

  /// Stream of achievements that just flipped to unlocked. Broadcast so
  /// multiple widgets (toast host + home card) can listen without
  /// stealing events from each other.
  Stream<Achievement> get unlockStream => _unlocks.stream;

  @override
  UserStats build() {
    ref.onDispose(_unlocks.close);
    return ref.read(userStatsServiceProvider).loadStats();
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
      handsWonDelta: playerWon ? 1 : 0,
      lessonsDelta: 0,
    );
  }

  /// Award XP for completing a lesson scenario.
  ///
  /// When [lessonId] and [scenarioIndex] are provided, the scenario is also
  /// marked as completed so the lessons list can show progress + mastery.
  Future<void> recordLessonComplete({
    String? lessonId,
    int? scenarioIndex,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final xp = Progression.xpPerLesson + streak.dailyBonusXp;

    Set<String>? newlyCompleted;
    if (lessonId != null && scenarioIndex != null) {
      final id = UserStats.scenarioId(lessonId, scenarioIndex);
      if (!prev.completedScenarioIds.contains(id)) {
        newlyCompleted = {...prev.completedScenarioIds, id};
      }
    }

    await _apply(
      prev: prev,
      streak: streak,
      xpDelta: xp,
      handsDelta: 0,
      handsWonDelta: 0,
      lessonsDelta: 1,
      completedScenarioIds: newlyCompleted,
    );
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
    required int handsWonDelta,
    required int lessonsDelta,
    Set<String>? completedScenarioIds,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;

    // Pre-achievement snapshot with all counter updates applied.
    final candidate = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      handsWon: prev.handsWon + handsWonDelta,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
      completedScenarioIds: completedScenarioIds,
    );

    // Check which achievements just unlocked and fold them into the
    // persisted set so we don't re-emit next time.
    final newUnlocks = newlyUnlockedAchievements(
      before: prev,
      after: candidate,
      catalog: achievementsCatalog,
    );
    final updated = newUnlocks.isEmpty
        ? candidate
        : candidate.copyWith(
            unlockedAchievementIds: {
              ...candidate.unlockedAchievementIds,
              ...newUnlocks,
            },
          );

    state = updated;
    await _service.saveStats(updated);

    // Emit unlocks AFTER persistence so listeners never see a toast for
    // an achievement that failed to save. A broadcast stream silently
    // drops events when no one is listening, which is exactly what we
    // want for transient toasts.
    if (newUnlocks.isNotEmpty && !_unlocks.isClosed) {
      final byId = {for (final a in achievementsCatalog) a.id: a};
      for (final id in newUnlocks) {
        final a = byId[id];
        if (a != null) _unlocks.add(a);
      }
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
