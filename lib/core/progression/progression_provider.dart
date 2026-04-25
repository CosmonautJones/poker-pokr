import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'scenario_mastery.dart';
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

/// Static catalog dimensions used by the achievement evaluator. Default is
/// an empty evaluator so the progression layer has no compile-time dependency
/// on the trainer feature — `main.dart` overrides this with the real lessons
/// catalog at app startup, and tests can supply their own.
final achievementEvaluatorProvider = Provider<AchievementEvaluator>((ref) {
  return AchievementEvaluator.disabled;
});

/// Live user stats snapshot. Rebuilds when [recordHandPlayed] /
/// [recordLessonComplete] / [resetAll] mutate state.
final userStatsProvider =
    NotifierProvider<UserStatsNotifier, UserStats>(UserStatsNotifier.new);

/// Haptics preference toggle. Writes through to SharedPreferences.
final hapticsEnabledProvider =
    NotifierProvider<HapticsPrefNotifier, bool>(HapticsPrefNotifier.new);

/// Queue of newly-earned achievements awaiting a unlock toast. UI listens
/// and pops the head as toasts dismiss.
final pendingAchievementsProvider =
    NotifierProvider<PendingAchievementsNotifier, List<AchievementId>>(
  PendingAchievementsNotifier.new,
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
      handsWonDelta: playerWon ? 1 : 0,
      lessonsDelta: 0,
    );
  }

  /// Award XP for completing a lesson scenario plus update its mastery
  /// record. [scenarioKey] is the value returned by [scenarioKeyFor]; pass
  /// null when called from legacy paths that don't track per-scenario data.
  /// [undoUsed] should be true if the player rewound at any point during
  /// this attempt — only "clean" attempts contribute to higher star tiers.
  Future<void> recordLessonComplete({
    String? scenarioKey,
    bool undoUsed = false,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final streak = Progression.applyActivity(prev, ts);
    final lessonXp = Progression.xpPerLesson + streak.dailyBonusXp;

    // Update mastery and award star-tier bonuses for first-time stars.
    Map<String, MasteryRecord>? newMastery;
    var starBonusXp = 0;
    if (scenarioKey != null) {
      final priorRecord =
          prev.scenarioMastery[scenarioKey] ?? const MasteryRecord.empty();
      final updated = priorRecord.recordCompletion(clean: !undoUsed, now: ts);
      newMastery = Map<String, MasteryRecord>.from(prev.scenarioMastery);
      newMastery[scenarioKey] = updated;
      // Award XP for each newly-earned star tier (e.g. record's bestStars
      // jumped from 1 → 2 means one bonus).
      final tierGain = updated.bestStars - priorRecord.bestStars;
      if (tierGain > 0) {
        starBonusXp = tierGain * Progression.xpPerStarTier;
      }
    }

    await _apply(
      prev: prev,
      streak: streak,
      xpDelta: lessonXp + starBonusXp,
      handsDelta: 0,
      handsWonDelta: 0,
      lessonsDelta: 1,
      newMastery: newMastery,
    );
  }

  /// Reset progression to a fresh install.
  Future<void> resetAll() async {
    state = const UserStats.empty();
    await _service.saveStats(state);
    ref.read(pendingAchievementsProvider.notifier).clear();
  }

  Future<void> _apply({
    required UserStats prev,
    required StreakResult streak,
    required int xpDelta,
    required int handsDelta,
    required int handsWonDelta,
    required int lessonsDelta,
    Map<String, MasteryRecord>? newMastery,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;

    var updated = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      handsWon: prev.handsWon + handsWonDelta,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
      scenarioMastery: newMastery ?? prev.scenarioMastery,
    );

    // Re-evaluate achievements. Newly-unlocked ones are queued for the toast
    // overlay and persisted to the unlocked set so they don't re-fire. We
    // loop until no further unlocks emerge so cascading triggers (e.g. an
    // achievement's XP bonus pushing the player into a new level which
    // itself unlocks another achievement) are all picked up in one pass.
    final evaluator = ref.read(achievementEvaluatorProvider);
    final freshAll = <AchievementId>[];
    // Cap iterations to defend against any future criteria that loop.
    for (var i = 0; i < 8; i++) {
      final fresh = evaluator.newlyUnlocked(updated);
      if (fresh.isEmpty) break;
      final unlockedKeys = Set<String>.from(updated.unlockedAchievementIds);
      for (final id in fresh) {
        unlockedKeys.add(id.key);
      }
      updated = updated.copyWith(
        totalXp:
            updated.totalXp + fresh.length * Progression.xpPerAchievement,
        unlockedAchievementIds: unlockedKeys,
      );
      freshAll.addAll(fresh);
    }
    if (freshAll.isNotEmpty) {
      ref.read(pendingAchievementsProvider.notifier).enqueueAll(freshAll);
    }

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

/// FIFO queue of unlock notifications. UI listens, shows the head as a
/// toast, then calls [dismissHead] when the player taps through.
class PendingAchievementsNotifier extends Notifier<List<AchievementId>> {
  @override
  List<AchievementId> build() => const [];

  void enqueueAll(List<AchievementId> ids) {
    if (ids.isEmpty) return;
    state = [...state, ...ids];
  }

  void dismissHead() {
    if (state.isEmpty) return;
    state = state.sublist(1);
  }

  void clear() {
    state = const [];
  }
}
