import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Queue of achievements unlocked since last drained by the UI.
///
/// The toast widget watches this; after rendering it calls
/// [PendingUnlocksNotifier.consume] which atomically pops the front entry.
/// Stays empty by default so first-run is silent.
final pendingAchievementUnlocksProvider = NotifierProvider<
    PendingUnlocksNotifier, List<Achievement>>(PendingUnlocksNotifier.new);

class UserStatsNotifier extends Notifier<UserStats> {
  @override
  UserStats build() => ref.read(userStatsServiceProvider).loadStats();

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  /// Award XP for finishing a hand.
  ///
  /// [playerWon] grants bonus XP when the viewer's player is among winners.
  /// [heroHandRankIndex] is the viewer's poker.engine.HandRank index at
  /// showdown (0..8). Pass null when the hand ended before showdown.
  Future<void> recordHandPlayed({
    bool playerWon = false,
    int? heroHandRankIndex,
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
      heroHandRankIndex: heroHandRankIndex,
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
      handsWonDelta: 0,
      heroHandRankIndex: null,
      lessonsDelta: 1,
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
    required int handsWonDelta,
    required int? heroHandRankIndex,
    required int lessonsDelta,
  }) async {
    final nextBest = streak.newStreakDays > prev.bestStreakDays
        ? streak.newStreakDays
        : prev.bestStreakDays;
    final nextHandRank = heroHandRankIndex != null &&
            heroHandRankIndex > prev.bestHandRankIndex
        ? heroHandRankIndex
        : prev.bestHandRankIndex;

    // First-pass update without achievement XP.
    final firstPass = prev.copyWith(
      streakDays: streak.newStreakDays,
      lastPlayedDay: streak.newLastPlayedDay,
      totalXp: prev.totalXp + xpDelta,
      handsPlayed: prev.handsPlayed + handsDelta,
      handsWon: prev.handsWon + handsWonDelta,
      bestHandRankIndex: nextHandRank,
      lessonsCompleted: prev.lessonsCompleted + lessonsDelta,
      bestStreakDays: nextBest,
    );

    // Detect newly-unlocked achievements after the activity.
    final newlyUnlocked = <Achievement>[];
    final unlockedIds = Set<String>.from(firstPass.unlockedAchievementIds);
    for (final a in AchievementsCatalog.all) {
      if (!unlockedIds.contains(a.id) && a.predicate(firstPass)) {
        unlockedIds.add(a.id);
        newlyUnlocked.add(a);
      }
    }

    final updated = firstPass.copyWith(
      unlockedAchievementIds: unlockedIds,
      totalXp: firstPass.totalXp +
          newlyUnlocked.length * Progression.xpPerAchievement,
    );

    // Persist first so a write failure doesn't desync in-memory state from
    // disk. If saveStats throws, callers see the prior state unchanged
    // and no toast is queued for the never-persisted unlocks.
    await _service.saveStats(updated);
    state = updated;

    if (newlyUnlocked.isNotEmpty) {
      ref
          .read(pendingAchievementUnlocksProvider.notifier)
          .enqueueAll(newlyUnlocked);
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

/// FIFO queue feeding the achievement-unlock toast UI. The notifier never
/// persists across launches: a toast missed because the app was closed is
/// fine, the achievement itself is still recorded in [UserStats].
class PendingUnlocksNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => const [];

  void enqueueAll(Iterable<Achievement> items) {
    if (items.isEmpty) return;
    state = [...state, ...items];
  }

  /// Pop and return the front entry, or null when the queue is empty.
  Achievement? consume() {
    if (state.isEmpty) return null;
    final next = state.first;
    state = state.sublist(1);
    return next;
  }

  void clear() {
    if (state.isEmpty) return;
    state = const [];
  }
}
