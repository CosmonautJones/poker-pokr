import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Stable identifiers for achievements. Persisted as strings, so renaming is
/// a breaking change — only append.
enum AchievementId {
  // Volume
  firstDeal,
  gettingComfortable,
  marathonPlayer,
  // Streak
  threeOnTheTrot,
  weekWarrior,
  lockedIn,
  // Mastery (lessons + level)
  eagerStudent,
  topOfTheClass,
  sharpEye,
  // Showdown
  firstPot,
  hotHand,
  bigWinner,
}

/// Coarse grouping for the Profile-screen layout. Order here is render order.
enum AchievementCategory {
  volume,
  streak,
  mastery,
  showdown,
}

extension AchievementCategoryX on AchievementCategory {
  String get label {
    switch (this) {
      case AchievementCategory.volume:
        return 'Volume';
      case AchievementCategory.streak:
        return 'Streak';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.showdown:
        return 'Showdown';
    }
  }
}

/// Static metadata describing one achievement.
///
/// [progress] returns a value in [0, 1] for the current progress toward
/// unlock; [isUnlocked] is the canonical boolean. Both are pure functions of
/// [UserStats], so a single snapshot drives the whole grid.
@immutable
class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;

  /// Threshold the relevant stat must reach to unlock. Used for the "X / N"
  /// progress label on the tile.
  final int threshold;

  /// Selector returning the relevant stat value for this achievement. Lets
  /// the catalog stay declarative without a switch in the evaluator.
  final int Function(UserStats stats) currentValue;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.threshold,
    required this.currentValue,
  });

  /// Progress in [0, 1]. Capped at 1 once unlocked.
  double progress(UserStats stats) {
    if (threshold <= 0) return 1.0;
    final v = currentValue(stats);
    if (v >= threshold) return 1.0;
    return (v / threshold).clamp(0.0, 1.0);
  }

  bool isUnlocked(UserStats stats) => currentValue(stats) >= threshold;
}
