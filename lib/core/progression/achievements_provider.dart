import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievement.dart';
import 'achievements_catalog.dart';
import 'achievements_service.dart';

/// Singleton provider for the SharedPreferences-backed achievements store.
/// Overridden in `main()` once SharedPreferences is initialized; tests
/// override with their own service.
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  throw UnimplementedError(
    'achievementsServiceProvider must be overridden with an '
    'AchievementsService instance (see main.dart).',
  );
});

/// Live set of unlocked achievement IDs the player has already been
/// celebrated for. Mutated via [AchievementsNotifier.markEarned] when a stat
/// transition crosses a threshold, and via [AchievementsNotifier.reset] from
/// Settings.
final achievementsProvider =
    NotifierProvider<AchievementsNotifier, Set<AchievementId>>(
  AchievementsNotifier.new,
);

/// One-shot stream of achievements that just unlocked, for the UI overlay
/// to consume. Distinct from [achievementsProvider] (the persisted set) so
/// listeners don't re-fire on every rebuild.
final newlyUnlockedProvider = StateProvider<List<AchievementId>>((_) => []);

class AchievementsNotifier extends Notifier<Set<AchievementId>> {
  @override
  Set<AchievementId> build() =>
      ref.read(achievementsServiceProvider).loadUnlocked();

  AchievementsService get _service =>
      ref.read(achievementsServiceProvider);

  /// Add [ids] to the persisted unlocked set. No-op for IDs already present.
  /// Returns the IDs that were genuinely newly unlocked (caller can use this
  /// to trigger celebrations).
  Future<List<AchievementId>> markEarned(Set<AchievementId> ids) async {
    final fresh = ids.difference(state);
    if (fresh.isEmpty) return const [];
    final next = {...state, ...fresh};
    state = next;
    await _service.saveUnlocked(next);
    // Preserve catalog order for a deterministic celebration sequence when
    // multiple achievements unlock from one stat transition.
    return [
      for (final a in achievementsCatalog)
        if (fresh.contains(a.id)) a.id,
    ];
  }

  /// Wipe persisted unlocks. Called from Settings → Reset progression.
  Future<void> reset() async {
    state = <AchievementId>{};
    await _service.clear();
  }
}
