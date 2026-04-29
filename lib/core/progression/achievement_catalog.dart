import 'package:flutter/material.dart';

import 'achievement.dart';

/// Canonical list of achievements shipped with the app.
///
/// Order is significant: it controls the display order in the badges grid
/// and the order in which simultaneous unlocks are surfaced to the user.
abstract final class AchievementCatalog {
  static final List<Achievement> all = [
    // ── Hands played ──
    Achievement(
      id: 'firstHand',
      title: 'First Hand',
      description: 'Play your first hand.',
      category: AchievementCategory.hands,
      targetValue: 1,
      iconData: Icons.style_rounded,
      progressFn: (s) => s.handsPlayed,
    ),
    Achievement(
      id: 'tenHands',
      title: 'Getting Warmed Up',
      description: 'Play 10 hands.',
      category: AchievementCategory.hands,
      targetValue: 10,
      iconData: Icons.casino_rounded,
      progressFn: (s) => s.handsPlayed,
    ),
    Achievement(
      id: 'hundredHands',
      title: 'Grinder',
      description: 'Play 100 hands.',
      category: AchievementCategory.hands,
      targetValue: 100,
      iconData: Icons.workspace_premium_rounded,
      progressFn: (s) => s.handsPlayed,
    ),
    // ── Wins ──
    Achievement(
      id: 'firstWin',
      title: 'First Pot',
      description: 'Win your first hand at showdown.',
      category: AchievementCategory.wins,
      targetValue: 1,
      iconData: Icons.emoji_events_outlined,
      progressFn: (s) => s.handsWon,
    ),
    Achievement(
      id: 'tenWins',
      title: 'Stacking Chips',
      description: 'Win 10 hands.',
      category: AchievementCategory.wins,
      targetValue: 10,
      iconData: Icons.emoji_events_rounded,
      progressFn: (s) => s.handsWon,
    ),
    Achievement(
      id: 'fiftyWins',
      title: 'Shark',
      description: 'Win 50 hands.',
      category: AchievementCategory.wins,
      targetValue: 50,
      iconData: Icons.military_tech_rounded,
      progressFn: (s) => s.handsWon,
    ),
    // ── Lessons ──
    Achievement(
      id: 'firstLesson',
      title: 'Bookworm',
      description: 'Complete your first lesson.',
      category: AchievementCategory.lessons,
      targetValue: 1,
      iconData: Icons.menu_book_rounded,
      progressFn: (s) => s.lessonsCompleted,
    ),
    Achievement(
      id: 'fiveLessons',
      title: 'Student of the Game',
      description: 'Complete 5 lessons.',
      category: AchievementCategory.lessons,
      targetValue: 5,
      iconData: Icons.school_rounded,
      progressFn: (s) => s.lessonsCompleted,
    ),
    Achievement(
      id: 'tenLessons',
      title: 'Theory Maven',
      description: 'Complete 10 lessons.',
      category: AchievementCategory.lessons,
      targetValue: 10,
      iconData: Icons.psychology_rounded,
      progressFn: (s) => s.lessonsCompleted,
    ),
    // ── Streak ──
    Achievement(
      id: 'weekStreak',
      title: 'Habit Forming',
      description: 'Reach a 7-day streak.',
      category: AchievementCategory.streak,
      targetValue: 7,
      iconData: Icons.local_fire_department_rounded,
      progressFn: (s) => s.bestStreakDays,
    ),
    Achievement(
      id: 'monthStreak',
      title: 'Iron Discipline',
      description: 'Reach a 30-day streak.',
      category: AchievementCategory.streak,
      targetValue: 30,
      iconData: Icons.whatshot_rounded,
      progressFn: (s) => s.bestStreakDays,
    ),
    // ── Level ──
    Achievement(
      id: 'levelFive',
      title: 'Rising Star',
      description: 'Reach level 5.',
      category: AchievementCategory.level,
      targetValue: 5,
      iconData: Icons.star_rounded,
      progressFn: (s) => s.level,
    ),
    Achievement(
      id: 'levelTen',
      title: 'Pro Mindset',
      description: 'Reach level 10.',
      category: AchievementCategory.level,
      targetValue: 10,
      iconData: Icons.auto_awesome_rounded,
      progressFn: (s) => s.level,
    ),
    // ── Mastery ──
    Achievement(
      id: 'xpThousand',
      title: 'Thousandaire',
      description: 'Earn 1000 lifetime XP.',
      category: AchievementCategory.mastery,
      targetValue: 1000,
      iconData: Icons.diamond_rounded,
      progressFn: (s) => s.totalXp,
    ),
  ];

  /// Lookup by id.
  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
