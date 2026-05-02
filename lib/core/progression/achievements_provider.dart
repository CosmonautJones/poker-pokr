import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/providers/lesson_progress_provider.dart';

/// Currently-unlocked achievement ids, derived live from stats + lesson
/// progress. Re-evaluates when either dependency changes.
final unlockedAchievementsProvider = Provider<Set<String>>((ref) {
  final stats = ref.watch(userStatsProvider);
  final lessons = ref.watch(lessonProgressProvider);
  return AchievementsEngine.evaluate(
    stats: stats,
    lessonProgress: lessons,
    lessons: lessonsCatalog,
  );
});

/// Tracks which achievement-unlock toasts the player has already seen, so
/// each unlock is celebrated exactly once. Persists through SharedPreferences.
final achievementsSeenProvider =
    NotifierProvider<AchievementsSeenNotifier, Set<String>>(
  AchievementsSeenNotifier.new,
);

class AchievementsSeenNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() =>
      ref.read(userStatsServiceProvider).loadAchievementsSeen();

  /// Mark [ids] as seen so they won't trigger another celebration.
  Future<void> markSeen(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    final next = {...state, ...ids};
    if (next.length == state.length) return;
    state = next;
    await ref.read(userStatsServiceProvider).saveAchievementsSeen(next);
  }

  Future<void> resetAll() async {
    state = <String>{};
    await ref.read(userStatsServiceProvider).clearAchievementsSeen();
  }
}
