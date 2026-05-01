import 'package:flutter/material.dart';

import '../../features/trainer/domain/lessons_catalog.dart';
import 'achievement.dart';

/// Total scenarios across every lesson — the bar for `lessons_complete`.
///
/// Derived from the live curriculum so adding scenarios automatically
/// raises the goal and stays internally consistent. Already-unlocked
/// players keep their badge because the unlock state is keyed by id.
final int kTotalLessonScenarios =
    lessonsCatalog.fold<int>(0, (n, l) => n + l.scenarios.length);

/// Static registry of every achievement the app can award.
///
/// Order matters: when multiple achievements unlock in the same stat update,
/// the toast queue replays them in catalog order.
abstract final class AchievementsCatalog {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_hand',
      title: 'First Hand',
      description: 'Completed your first hand replay.',
      hint: 'Finish a hand replay.',
      icon: Icons.flag_rounded,
      tier: AchievementTier.bronze,
      test: (s) => s.handsPlayed >= 1,
    ),
    Achievement(
      id: 'first_lesson',
      title: 'First Lesson',
      description: 'Completed your first lesson scenario.',
      hint: 'Finish a lesson scenario.',
      icon: Icons.school_rounded,
      tier: AchievementTier.bronze,
      test: (s) => s.lessonsCompleted >= 1,
    ),
    Achievement(
      id: 'hands_50',
      title: 'Grinder',
      description: 'Played 50 hands.',
      hint: 'Play 50 hands.',
      icon: Icons.casino_rounded,
      tier: AchievementTier.silver,
      test: (s) => s.handsPlayed >= 50,
    ),
    Achievement(
      id: 'hands_250',
      title: 'Volume Veteran',
      description: 'Played 250 hands.',
      hint: 'Play 250 hands.',
      icon: Icons.workspace_premium_rounded,
      tier: AchievementTier.gold,
      test: (s) => s.handsPlayed >= 250,
    ),
    Achievement(
      id: 'lessons_5',
      title: 'Apprentice',
      description: 'Completed 5 lesson scenarios.',
      hint: 'Complete 5 lesson scenarios.',
      icon: Icons.menu_book_rounded,
      tier: AchievementTier.silver,
      test: (s) => s.lessonsCompleted >= 5,
    ),
    Achievement(
      id: 'lessons_complete',
      title: 'Curriculum Master',
      description: 'Completed every lesson scenario.',
      hint: 'Complete the full lesson curriculum.',
      icon: Icons.military_tech_rounded,
      tier: AchievementTier.gold,
      test: (s) => s.lessonsCompleted >= kTotalLessonScenarios,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Warming Up',
      description: 'Played 3 days in a row.',
      hint: 'Play 3 days in a row.',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.bronze,
      test: (s) => s.bestStreakDays >= 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'On Fire',
      description: 'Played 7 days in a row.',
      hint: 'Play a full week in a row.',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.silver,
      test: (s) => s.bestStreakDays >= 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Unbreakable',
      description: 'Played 30 days in a row.',
      hint: 'Maintain a 30-day streak.',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.gold,
      test: (s) => s.bestStreakDays >= 30,
    ),
    Achievement(
      id: 'level_5',
      title: 'Level 5',
      description: 'Reached level 5.',
      hint: 'Reach level 5.',
      icon: Icons.trending_up_rounded,
      tier: AchievementTier.silver,
      test: (s) => s.level >= 5,
    ),
    Achievement(
      id: 'level_10',
      title: 'Double Digits',
      description: 'Reached level 10.',
      hint: 'Reach level 10.',
      icon: Icons.star_rounded,
      tier: AchievementTier.gold,
      test: (s) => s.level >= 10,
    ),
    Achievement(
      id: 'xp_1000',
      title: 'XP Collector',
      description: 'Earned 1,000 lifetime XP.',
      hint: 'Earn 1,000 lifetime XP.',
      icon: Icons.bolt_rounded,
      tier: AchievementTier.silver,
      test: (s) => s.totalXp >= 1000,
    ),
  ];

  /// Lookup by stable id; returns null for unknown ids.
  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
