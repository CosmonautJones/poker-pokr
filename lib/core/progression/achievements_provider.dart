import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements/achievement.dart';
import 'achievements/achievement_event.dart';
import 'achievements/achievement_progress.dart';
import 'achievements/achievements_catalog.dart';
import 'achievements/daily_challenge.dart';
import 'progression_provider.dart';

/// Side-channel result of dispatching an event: which achievements just
/// unlocked, plus the daily-challenge-just-completed flag.
///
/// Listened to by UI for celebration overlays. Empty when nothing happened.
class AchievementDispatchResult {
  final List<Achievement> newlyUnlocked;
  final bool dailyJustCompleted;

  const AchievementDispatchResult({
    required this.newlyUnlocked,
    required this.dailyJustCompleted,
  });

  static const empty = AchievementDispatchResult(
    newlyUnlocked: <Achievement>[],
    dailyJustCompleted: false,
  );

  bool get hasAny => newlyUnlocked.isNotEmpty || dailyJustCompleted;
}

/// Live achievements state — unlocks + per-achievement progress.
final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
        AchievementsNotifier.new);

/// Live daily challenge for the current calendar day.
final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallenge>(
        DailyChallengeNotifier.new);

/// Surfaces the most recent dispatch result so the UI can show a one-shot
/// celebration. Consumers should clear it after displaying.
final lastDispatchResultProvider =
    NotifierProvider<LastDispatchResultNotifier, AchievementDispatchResult>(
        LastDispatchResultNotifier.new);

class AchievementsNotifier extends Notifier<AchievementsState> {
  @override
  AchievementsState build() {
    return ref.read(userStatsServiceProvider).loadAchievements();
  }

  /// Process [event] against the catalog. Stores updated progress, unlocks
  /// any thresholds that were crossed, awards XP, and surfaces the unlock
  /// list via [lastDispatchResultProvider].
  Future<List<Achievement>> dispatch(
    AchievementEvent event, {
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final prev = state;
    final nextById =
        Map<String, AchievementProgress>.from(prev.byId);
    final unlocked = <Achievement>[];
    var totalXpReward = 0;
    var anyChange = false;

    for (final ach in achievementsCatalog) {
      final prior = nextById[ach.id] ??
          const AchievementProgress(value: 0);
      final newValue = ach.progressFn(event, prior.value);
      // Catalog progress functions are monotonic — they either return the
      // prior value (no-op for this event) or a strictly greater one. If a
      // future contributor adds a non-monotonic fn, the unlock guard below
      // still prevents flapping (unlockedAt is only set once).
      if (newValue == prior.value) continue;
      final justUnlocked = prior.unlockedAt == null &&
          newValue >= ach.threshold;
      nextById[ach.id] = AchievementProgress(
        value: newValue,
        unlockedAt: justUnlocked ? ts : prior.unlockedAt,
      );
      anyChange = true;
      if (justUnlocked) {
        unlocked.add(ach);
        totalXpReward += ach.xpReward;
      }
    }

    if (anyChange) {
      final nextState = AchievementsState(byId: nextById);
      state = nextState;
      await ref
          .read(userStatsServiceProvider)
          .saveAchievements(nextState);
    }

    if (totalXpReward > 0) {
      // Lazy lookup so a future stats refactor doesn't break us.
      await ref
          .read(userStatsProvider.notifier)
          .awardXpForAchievements(totalXpReward);
    }

    return unlocked;
  }

  /// Wipe all unlocks + progress. Used by the settings reset path.
  Future<void> resetAll() async {
    state = const AchievementsState.empty();
    await ref.read(userStatsServiceProvider).clearAchievements();
  }
}

class DailyChallengeNotifier extends Notifier<DailyChallenge> {
  @override
  DailyChallenge build() {
    final svc = ref.read(userStatsServiceProvider);
    final loaded = svc.loadDailyChallenge();
    final ensured = DailyChallenge.ensureForToday(loaded, DateTime.now());
    if (loaded == null || loaded.day != ensured.day) {
      // Fire-and-forget: persisting the rolled challenge once on first read
      // so subsequent loads see a stable id.
      Future<void>.microtask(() => svc.saveDailyChallenge(ensured));
    }
    return ensured;
  }

  /// Update progress against the active challenge. Returns true if the
  /// challenge transitioned from incomplete to complete on this dispatch.
  Future<bool> dispatch(AchievementEvent event, {DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final fresh = DailyChallenge.ensureForToday(state, ts);
    final tpl = fresh.template;
    if (tpl == null) {
      state = fresh;
      await ref
          .read(userStatsServiceProvider)
          .saveDailyChallenge(fresh);
      return false;
    }
    final wasComplete = fresh.isComplete;
    final nextProgress = tpl.progressFn(event, fresh.progress);
    if (nextProgress == fresh.progress && fresh == state) {
      return false;
    }
    final updated = fresh.copyWith(progress: nextProgress);
    state = updated;
    await ref
        .read(userStatsServiceProvider)
        .saveDailyChallenge(updated);
    final justCompleted = !wasComplete && updated.isComplete;
    return justCompleted;
  }

  /// Claim the challenge reward. No-op if not complete or already claimed.
  /// Returns the XP awarded (0 when nothing to claim).
  Future<int> claim() async {
    final ts = DateTime.now();
    final fresh = DailyChallenge.ensureForToday(state, ts);
    final tpl = fresh.template;
    if (tpl == null || !fresh.isComplete || fresh.claimed) {
      if (fresh != state) {
        state = fresh;
        await ref
            .read(userStatsServiceProvider)
            .saveDailyChallenge(fresh);
      }
      return 0;
    }
    final updated = fresh.copyWith(claimed: true);
    state = updated;
    await ref
        .read(userStatsServiceProvider)
        .saveDailyChallenge(updated);
    await ref
        .read(userStatsProvider.notifier)
        .awardXpForAchievements(tpl.xpReward);
    return tpl.xpReward;
  }

  /// Force a fresh roll (used by reset path).
  Future<void> resetForToday() async {
    final fresh = DailyChallenge.rollFor(DateTime.now());
    state = fresh;
    await ref
        .read(userStatsServiceProvider)
        .saveDailyChallenge(fresh);
  }
}

class LastDispatchResultNotifier extends Notifier<AchievementDispatchResult> {
  @override
  AchievementDispatchResult build() => AchievementDispatchResult.empty;

  void set(AchievementDispatchResult next) {
    state = next;
  }

  void clear() {
    if (state.hasAny) state = AchievementDispatchResult.empty;
  }
}
