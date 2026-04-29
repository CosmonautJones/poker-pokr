import 'package:flutter/widgets.dart';

import 'user_stats.dart';

/// Top-level grouping for badges. Used by the badges screen for filters and
/// for default icon coloring.
enum AchievementCategory {
  hands,
  wins,
  streak,
  lessons,
  level,
  mastery,
}

/// Pure description of an unlockable badge.
///
/// The [progressFn] takes a [UserStats] snapshot and returns the player's
/// current progress towards [targetValue] (clamped to non-negative). The
/// badge is unlocked once the returned value reaches the target.
///
/// Achievement definitions are static data — keep this class free of
/// Flutter framework dependencies beyond the [IconData] needed for the
/// badges grid.
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;
  final int targetValue;
  final IconData iconData;
  final int Function(UserStats stats) progressFn;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.targetValue,
    required this.iconData,
    required this.progressFn,
  });

  /// Current progress (0..[targetValue]) for [stats].
  int progressFor(UserStats stats) {
    final raw = progressFn(stats);
    if (raw < 0) return 0;
    if (raw > targetValue) return targetValue;
    return raw;
  }

  /// Normalized progress in [0, 1] — useful for progress bars.
  double progressFraction(UserStats stats) {
    if (targetValue <= 0) return 1.0;
    return progressFor(stats) / targetValue;
  }

  /// Whether [stats] satisfies this achievement's unlock condition.
  bool isUnlockedBy(UserStats stats) => progressFor(stats) >= targetValue;
}
