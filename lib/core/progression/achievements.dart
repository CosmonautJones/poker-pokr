import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Stable enum identifying each achievement. Persisted as the enum name.
enum AchievementId {
  firstHand,
  hundredHands,
  fiveDayStreak,
  tenDayStreak,
  lessonGraduate,
  perfectionist,
  showdownSlayer,
  levelFive,
}

/// Static achievement definition. [isUnlocked] is a pure predicate over
/// [UserStats] so unlock evaluation has no side effects.
class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final IconData icon;
  final bool Function(UserStats stats) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.isUnlocked,
  });
}

/// Catalog of all achievements. Order = display order in the gallery.
final List<Achievement> kAchievements = <Achievement>[
  Achievement(
    id: AchievementId.firstHand,
    title: 'First Hand',
    description: 'Complete your first hand',
    icon: Icons.auto_awesome_rounded,
    isUnlocked: (s) => s.handsPlayed >= 1,
  ),
  Achievement(
    id: AchievementId.hundredHands,
    title: 'Centurion',
    description: 'Play 100 hands',
    icon: Icons.workspace_premium_rounded,
    isUnlocked: (s) => s.handsPlayed >= 100,
  ),
  Achievement(
    id: AchievementId.fiveDayStreak,
    title: 'Daily Habit',
    description: 'Reach a 5-day streak',
    icon: Icons.local_fire_department_rounded,
    isUnlocked: (s) => s.bestStreakDays >= 5,
  ),
  Achievement(
    id: AchievementId.tenDayStreak,
    title: 'Ironclad',
    description: 'Reach a 10-day streak',
    icon: Icons.shield_rounded,
    isUnlocked: (s) => s.bestStreakDays >= 10,
  ),
  Achievement(
    id: AchievementId.lessonGraduate,
    title: 'Lesson Graduate',
    description: 'Complete 5 lessons',
    icon: Icons.school_rounded,
    isUnlocked: (s) => s.lessonsCompleted >= 5,
  ),
  Achievement(
    id: AchievementId.perfectionist,
    title: 'Perfectionist',
    description: 'Complete 10 lessons',
    icon: Icons.verified_rounded,
    isUnlocked: (s) => s.lessonsCompleted >= 10,
  ),
  Achievement(
    id: AchievementId.showdownSlayer,
    title: 'Showdown Slayer',
    description: 'Win 10 hands at showdown',
    icon: Icons.emoji_events_rounded,
    isUnlocked: (s) => s.handsWon >= 10,
  ),
  Achievement(
    id: AchievementId.levelFive,
    title: 'Rising Star',
    description: 'Reach level 5',
    icon: Icons.star_rounded,
    isUnlocked: (s) => s.level >= 5,
  ),
];

/// Pure helpers for evaluating achievement state from a [UserStats] snapshot.
abstract final class AchievementsAlgorithm {
  /// Returns the set of [AchievementId]s currently unlocked given [stats].
  static Set<AchievementId> evaluate(UserStats stats) {
    return <AchievementId>{
      for (final a in kAchievements)
        if (a.isUnlocked(stats)) a.id,
    };
  }

  /// Look up a definition by id. Returns null if the catalog has been
  /// reduced (shouldn't happen — values come from the same enum).
  static Achievement? definition(AchievementId id) {
    for (final a in kAchievements) {
      if (a.id == id) return a;
    }
    return null;
  }
}
