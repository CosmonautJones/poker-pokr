import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Domain category groupings for the achievements grid.
enum AchievementCategory {
  volume,
  winning,
  streak,
  mastery,
  bigHand;

  String get displayName => switch (this) {
        AchievementCategory.volume => 'Volume',
        AchievementCategory.winning => 'Winning',
        AchievementCategory.streak => 'Streak',
        AchievementCategory.mastery => 'Mastery',
        AchievementCategory.bigHand => 'Big Hands',
      };
}

/// A single unlockable achievement.
///
/// `predicate` is a pure function over a [UserStats] snapshot so the
/// evaluator can run without side effects and tests can verify each rule
/// independently.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementCategory category;

  /// Returns true when [stats] satisfies this achievement's unlock rule.
  final bool Function(UserStats stats) predicate;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
    required this.predicate,
  });
}

/// Static registry of every achievement available in the app.
///
/// Order is the display order in the achievements grid (within each
/// category). Adding a new achievement is a one-line append; ids must be
/// stable forever once shipped because they're persisted in user storage.
abstract final class AchievementsCatalog {
  static final List<Achievement> all = [
    // ---- Volume ----
    Achievement(
      id: 'first_hand',
      title: 'First Hand',
      description: 'Complete your first practice hand.',
      icon: Icons.flag_rounded,
      category: AchievementCategory.volume,
      predicate: (s) => s.handsPlayed >= 1,
    ),
    Achievement(
      id: 'apprentice',
      title: 'Apprentice',
      description: 'Complete 10 hands.',
      icon: Icons.school_rounded,
      category: AchievementCategory.volume,
      predicate: (s) => s.handsPlayed >= 10,
    ),
    Achievement(
      id: 'sharp',
      title: 'Sharp',
      description: 'Complete 50 hands.',
      icon: Icons.psychology_rounded,
      category: AchievementCategory.volume,
      predicate: (s) => s.handsPlayed >= 50,
    ),
    Achievement(
      id: 'veteran',
      title: 'Veteran',
      description: 'Complete 250 hands.',
      icon: Icons.military_tech_rounded,
      category: AchievementCategory.volume,
      predicate: (s) => s.handsPlayed >= 250,
    ),

    // ---- Winning ----
    Achievement(
      id: 'first_win',
      title: 'First Win',
      description: 'Win your first hand.',
      icon: Icons.emoji_events_rounded,
      category: AchievementCategory.winning,
      predicate: (s) => s.handsWon >= 1,
    ),
    Achievement(
      id: 'closer',
      title: 'Closer',
      description: 'Win 10 hands.',
      icon: Icons.star_rounded,
      category: AchievementCategory.winning,
      predicate: (s) => s.handsWon >= 10,
    ),
    Achievement(
      id: 'crusher',
      title: 'Crusher',
      description: 'Win 50 hands.',
      icon: Icons.workspace_premium_rounded,
      category: AchievementCategory.winning,
      predicate: (s) => s.handsWon >= 50,
    ),

    // ---- Streak ----
    Achievement(
      id: 'hot_streak',
      title: 'Hot Streak',
      description: 'Play 3 days in a row.',
      icon: Icons.local_fire_department_rounded,
      category: AchievementCategory.streak,
      predicate: (s) => s.bestStreakDays >= 3,
    ),
    Achievement(
      id: 'week_warrior',
      title: 'Week Warrior',
      description: 'Play 7 days in a row.',
      icon: Icons.bolt_rounded,
      category: AchievementCategory.streak,
      predicate: (s) => s.bestStreakDays >= 7,
    ),
    Achievement(
      id: 'unbreakable',
      title: 'Unbreakable',
      description: 'Hit a 30-day streak.',
      icon: Icons.shield_rounded,
      category: AchievementCategory.streak,
      predicate: (s) => s.bestStreakDays >= 30,
    ),

    // ---- Mastery ----
    Achievement(
      id: 'first_lesson',
      title: 'Curious Mind',
      description: 'Complete your first lesson.',
      icon: Icons.menu_book_rounded,
      category: AchievementCategory.mastery,
      predicate: (s) => s.lessonsCompleted >= 1,
    ),
    Achievement(
      id: 'scholar',
      title: 'Scholar',
      description: 'Complete 5 lessons.',
      icon: Icons.auto_stories_rounded,
      category: AchievementCategory.mastery,
      predicate: (s) => s.lessonsCompleted >= 5,
    ),
    Achievement(
      id: 'rising_star',
      title: 'Rising Star',
      description: 'Reach Level 5.',
      icon: Icons.trending_up_rounded,
      category: AchievementCategory.mastery,
      predicate: (s) => s.level >= 5,
    ),
    Achievement(
      id: 'table_master',
      title: 'Table Master',
      description: 'Reach Level 10.',
      icon: Icons.diamond_rounded,
      category: AchievementCategory.mastery,
      predicate: (s) => s.level >= 10,
    ),

    // ---- Big Hand ----
    // bestHandRankIndex follows poker.engine.HandRank order:
    // 0 highCard, 1 pair, 2 twoPair, 3 threeOfAKind, 4 straight,
    // 5 flush, 6 fullHouse, 7 fourOfAKind, 8 straightFlush.
    Achievement(
      id: 'big_hand_flush',
      title: 'In the Suit',
      description: 'Hit a flush at showdown.',
      icon: Icons.water_drop_rounded,
      category: AchievementCategory.bigHand,
      predicate: (s) => s.bestHandRankIndex >= 5,
    ),
    Achievement(
      id: 'big_hand_full_house',
      title: 'Full Boat',
      description: 'Hit a full house at showdown.',
      icon: Icons.directions_boat_rounded,
      category: AchievementCategory.bigHand,
      predicate: (s) => s.bestHandRankIndex >= 6,
    ),
    Achievement(
      id: 'big_hand_quads',
      title: 'Quads',
      description: 'Hit four of a kind at showdown.',
      icon: Icons.dashboard_rounded,
      category: AchievementCategory.bigHand,
      predicate: (s) => s.bestHandRankIndex >= 7,
    ),
    Achievement(
      id: 'big_hand_straight_flush',
      title: 'Straight Flush',
      description: 'Hit a straight flush — the rarest of feats.',
      icon: Icons.auto_awesome_rounded,
      category: AchievementCategory.bigHand,
      predicate: (s) => s.bestHandRankIndex >= 8,
    ),
  ];

  /// O(1) lookup by id. Returns null for ids that no longer exist (defensive).
  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}
