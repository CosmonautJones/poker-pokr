import 'package:flutter/material.dart';

import 'achievement_event.dart';

/// Visual tier of an achievement — drives badge color + sort weight.
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum;

  /// Higher tiers sort later within the same group on the wall.
  int get weight => index;
}

/// Categories used to group the achievement wall and to derive a daily
/// challenge variety.
enum AchievementCategory {
  volume, // hand counts
  mastery, // hand-class wins
  drills, // lessons
  habit, // streak / level
  variety, // omaha, all-in
}

/// Definition of one achievement in the catalog.
///
/// [progressFn] produces the new running value for this achievement given an
/// [AchievementEvent] and the prior value. Returning the same value means
/// "no change". Once value reaches [threshold] for the first time the
/// achievement unlocks (and stays unlocked even if a future event somehow
/// reduced the value — unlock is monotonic).
@immutable
class Achievement {
  /// Stable identifier used for persistence; never rename.
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final AchievementCategory category;
  final int threshold;
  final int xpReward;

  /// Progress evaluator — pure, deterministic. Implementations should treat
  /// the returned value as the *new* total to record for this achievement.
  final int Function(AchievementEvent event, int currentValue) progressFn;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.category,
    required this.threshold,
    required this.xpReward,
    required this.progressFn,
  });

  /// Convenience: counter that increments by 1 when [match] returns true.
  static int Function(AchievementEvent, int) counter(
    bool Function(AchievementEvent event) match,
  ) {
    return (event, current) => match(event) ? current + 1 : current;
  }

  /// Convenience: tracker that takes the max of an event-derived value
  /// (used for streak / level achievements).
  static int Function(AchievementEvent, int) maxOf(
    int? Function(AchievementEvent event) extract,
  ) {
    return (event, current) {
      final v = extract(event);
      if (v == null) return current;
      return v > current ? v : current;
    };
  }
}
