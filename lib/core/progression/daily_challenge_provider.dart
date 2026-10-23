import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'daily_challenge.dart';
import 'progression_provider.dart';
import 'user_stats_service.dart';

/// Today's daily challenge state. Auto-rolls when the local calendar day
/// changes between launches.
final dailyChallengeProvider =
    NotifierProvider<DailyChallengeNotifier, DailyChallenge>(
  DailyChallengeNotifier.new,
);

class DailyChallengeNotifier extends Notifier<DailyChallenge> {
  UserStatsService get _service => ref.read(userStatsServiceProvider);

  @override
  DailyChallenge build() {
    final now = DateTime.now();
    final today = ChallengeAlgorithm.dayKey(now);
    final stored = _service.loadChallenge();
    if (stored != null && stored.dayKey == today) {
      // Same day, same persisted state. The stored templateId may not match
      // today's deterministic pick if the catalog changed mid-day — keep
      // the persisted one to honor work already in progress.
      return stored;
    }
    final fresh = DailyChallenge.fresh(
      dayKey: today,
      template: ChallengeAlgorithm.templateForDay(now),
    );
    // Fire-and-forget save; provider build must remain synchronous.
    _service.saveChallenge(fresh);
    return fresh;
  }

  /// Active template resolved from the current state's templateId. Falls
  /// back to today's deterministic pick if the id doesn't resolve (catalog
  /// drift) — UI can rely on this being non-null.
  ChallengeTemplate get template =>
      ChallengeAlgorithm.findTemplate(state.templateId) ??
      ChallengeAlgorithm.templateForDay(DateTime.now());

  /// Record one occurrence of [kind]. Awards XP into [userStatsProvider]
  /// when the event flips the challenge to complete. Idempotent after
  /// completion.
  Future<void> recordEvent(ChallengeKind kind, {DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final today = ChallengeAlgorithm.dayKey(ts);
    // Day rolled over since build (rare but possible in long-running session).
    if (state.dayKey != today) {
      final fresh = DailyChallenge.fresh(
        dayKey: today,
        template: ChallengeAlgorithm.templateForDay(ts),
      );
      state = fresh;
      await _service.saveChallenge(fresh);
    }

    final tpl = template;
    final result = ChallengeAlgorithm.applyEvent(
      challenge: state,
      template: tpl,
      kind: kind,
    );
    if (identical(result.next, state)) return;
    state = result.next;
    await _service.saveChallenge(state);
    if (result.completionXp > 0) {
      await ref
          .read(userStatsProvider.notifier)
          .awardBonusXp(result.completionXp);
    }
  }

  /// Wipe persisted challenge state and re-mint a fresh one for today.
  Future<void> resetAll({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    await _service.clearChallenge();
    final fresh = DailyChallenge.fresh(
      dayKey: ChallengeAlgorithm.dayKey(ts),
      template: ChallengeAlgorithm.templateForDay(ts),
    );
    state = fresh;
    await _service.saveChallenge(fresh);
  }
}
