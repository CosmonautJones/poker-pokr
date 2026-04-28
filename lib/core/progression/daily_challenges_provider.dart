import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_challenges.dart';
import 'daily_challenges_service.dart';
import 'progression_provider.dart';

/// Singleton service provider — overridden in `main()` after
/// SharedPreferences initialisation; tests inject an in-memory stub.
final dailyChallengesServiceProvider = Provider<DailyChallengesService>((ref) {
  throw UnimplementedError(
    'dailyChallengesServiceProvider must be overridden with a '
    'DailyChallengesService instance (see main.dart).',
  );
});

/// Live snapshot of today's challenge slate.
///
/// Built via [AsyncNotifier] because the initial load awaits SharedPreferences
/// (and may regenerate on day rollover).
final dailyChallengesProvider = AsyncNotifierProvider<
    DailyChallengesNotifier, List<DailyChallenge>>(DailyChallengesNotifier.new);

class DailyChallengesNotifier
    extends AsyncNotifier<List<DailyChallenge>> {
  @override
  Future<List<DailyChallenge>> build() {
    return ref.read(dailyChallengesServiceProvider).loadForToday();
  }

  DailyChallengesService get _service =>
      ref.read(dailyChallengesServiceProvider);

  /// Apply a delta to a single challenge id. If the increment completes the
  /// challenge, grants `xpReward` via the user-stats notifier and returns the
  /// freshly-completed [DailyChallenge] (callers can then surface a toast).
  ///
  /// Idempotent for already-completed challenges — additional increments are
  /// silently dropped.
  Future<DailyChallenge?> incrementProgress(
    String challengeId,
    int amount, {
    DateTime? now,
  }) async {
    if (amount <= 0) return null;
    final current = state.valueOrNull;
    if (current == null) return null;
    final result = DailyChallenges.applyIncrement(current, challengeId, amount);
    if (identical(result.list, current)) return null;
    state = AsyncData(result.list);
    await _service.save(result.list);
    final completed = result.justCompleted;
    if (completed != null) {
      final def = DailyChallenges.byId(completed.definitionId);
      if (def != null) {
        await ref
            .read(userStatsProvider.notifier)
            .awardChallengeXp(def.xpReward, now: now);
      }
    }
    return completed;
  }

  /// Force a challenge to the completed state (used by manual "claim" flows
  /// in the future). XP is granted exactly once.
  Future<DailyChallenge?> completeChallenge(
    String challengeId, {
    DateTime? now,
  }) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    final idx =
        current.indexWhere((c) => c.definitionId == challengeId);
    if (idx < 0) return null;
    final ch = current[idx];
    if (ch.completed) return null;
    final def = DailyChallenges.byId(challengeId);
    if (def == null) return null;
    final updated = ch.copyWith(progress: def.target, completed: true);
    final next = List<DailyChallenge>.from(current);
    next[idx] = updated;
    state = AsyncData(next);
    await _service.save(next);
    await ref
        .read(userStatsProvider.notifier)
        .awardChallengeXp(def.xpReward, now: now);
    return updated;
  }

  /// Force-regenerate today's slate (used by tests / pull-to-refresh).
  Future<void> refresh({DateTime? now}) async {
    state = const AsyncLoading();
    final list = await _service.loadForToday(now: now);
    state = AsyncData(list);
  }
}
