import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'progression_provider.dart';
import 'user_stats.dart';
import 'user_stats_service.dart';

/// Currently-unlocked achievement ids. Recomputes whenever [userStatsProvider]
/// emits a new snapshot. New unlocks are appended to a pending queue that the
/// listener drains to fire UI banners.
final achievementsProvider =
    NotifierProvider<AchievementsNotifier, Set<AchievementId>>(
  AchievementsNotifier.new,
);

class AchievementsNotifier extends Notifier<Set<AchievementId>> {
  /// IDs that have unlocked since the last [drainPendingUnlocks] call.
  final List<AchievementId> _pending = <AchievementId>[];

  UserStatsService get _service => ref.read(userStatsServiceProvider);

  @override
  Set<AchievementId> build() {
    final persistedRaw = _service.loadAchievements();
    final persisted = <AchievementId>{
      for (final raw in persistedRaw)
        for (final v in AchievementId.values)
          if (v.name == raw) v,
    };
    // Re-evaluate against current stats so an install with prior progress
    // reconciles silently without firing banners for already-earned badges.
    final stats = ref.read(userStatsProvider);
    final evaluated = AchievementsAlgorithm.evaluate(stats);
    final merged = persisted.union(evaluated);

    // If reconciliation added new ids, persist (but don't queue them — the
    // user already earned them on a prior run / before the listener mounted).
    if (merged.length != persisted.length) {
      _service.saveAchievements({for (final id in merged) id.name});
    }

    // Subscribe to subsequent stats updates to detect future unlocks.
    ref.listen<UserStats>(
      userStatsProvider,
      (_, __) => _reEvaluate(),
    );

    return merged;
  }

  Future<void> _reEvaluate() async {
    final stats = ref.read(userStatsProvider);
    final evaluated = AchievementsAlgorithm.evaluate(stats);
    final newly = evaluated.difference(state);
    if (newly.isEmpty) return;
    _pending.addAll(newly);
    final merged = state.union(newly);
    state = merged;
    await _service.saveAchievements({for (final id in merged) id.name});
  }

  /// Removes and returns all unlocks queued since the last drain. UI calls
  /// this from a `ref.listen(userStatsProvider)` to fire banners.
  List<AchievementId> drainPendingUnlocks() {
    if (_pending.isEmpty) return const [];
    final out = List<AchievementId>.from(_pending);
    _pending.clear();
    return out;
  }

  /// Clears persisted unlocks. Called by the progression reset flow.
  Future<void> resetAll() async {
    _pending.clear();
    state = <AchievementId>{};
    await _service.clearAchievements();
  }
}
