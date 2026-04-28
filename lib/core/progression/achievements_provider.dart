import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'achievements_service.dart';
import 'user_stats.dart';

/// Singleton service provider — overridden in `main()` after
/// SharedPreferences initialisation; tests inject an in-memory stub.
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  throw UnimplementedError(
    'achievementsServiceProvider must be overridden with an '
    'AchievementsService instance (see main.dart).',
  );
});

/// Live snapshot of the achievement list.
final achievementsProvider =
    NotifierProvider<AchievementsNotifier, List<Achievement>>(
  AchievementsNotifier.new,
);

class AchievementsNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => ref.read(achievementsServiceProvider).load();

  AchievementsService get _service =>
      ref.read(achievementsServiceProvider);

  /// Re-run the rule engine against [stats] and optional [ctx]. Returns the
  /// list of newly-unlocked achievements (empty when nothing changed).
  Future<List<Achievement>> evaluate(
    UserStats stats, {
    AchievementContext? ctx,
    DateTime? now,
  }) async {
    final prev = state;
    final next = Achievements.evaluate(
      current: prev,
      stats: stats,
      ctx: ctx,
      now: now,
    );
    final unlocked = Achievements.newlyUnlocked(prev: prev, next: next);
    if (unlocked.isEmpty) return const [];
    state = next;
    await _service.save(next);
    return unlocked;
  }

  /// Wipe to a fresh-install state.
  Future<void> resetAll() async {
    state = Achievements.defaults();
    await _service.save(state);
  }
}
