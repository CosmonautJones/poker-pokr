import 'achievement.dart';
import 'achievement_catalog.dart';
import 'user_stats.dart';

/// Result of running [AchievementEngine.evaluate] against a stats snapshot.
class EvaluationResult {
  /// Full set of achievement ids that should be considered unlocked after
  /// this evaluation. Always a superset of the previously-unlocked set.
  final Set<String> unlocked;

  /// Achievements that just transitioned from locked to unlocked, in
  /// catalog order. Empty when no new unlocks occurred.
  final List<Achievement> justUnlocked;

  const EvaluationResult({
    required this.unlocked,
    required this.justUnlocked,
  });
}

/// Pure function from (stats, previously-unlocked) to (newly-unlocked
/// superset, just-unlocked diff). Never demotes an already-unlocked badge.
abstract final class AchievementEngine {
  static EvaluationResult evaluate(
    UserStats stats,
    Set<String> previouslyUnlocked,
  ) {
    final unlocked = <String>{...previouslyUnlocked};
    final newlyUnlocked = <Achievement>[];
    for (final a in AchievementCatalog.all) {
      if (a.isUnlockedBy(stats) && !unlocked.contains(a.id)) {
        unlocked.add(a.id);
        newlyUnlocked.add(a);
      }
    }
    return EvaluationResult(
      unlocked: unlocked,
      justUnlocked: newlyUnlocked,
    );
  }

  /// Convenience helper for the badges grid: progress in [0, 1] for the
  /// given [achievement] under [stats].
  static double progressOf(Achievement achievement, UserStats stats) {
    return achievement.progressFraction(stats);
  }
}
