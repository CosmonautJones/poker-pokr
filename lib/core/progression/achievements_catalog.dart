import 'package:flutter/material.dart';

import 'achievement.dart';
import 'user_stats.dart';

/// Total number of lesson scenarios shipping in the app today. Kept in sync
/// with `lessons_catalog.dart`: 4 drawing-hand scenarios + 2 protection = 6.
/// If lesson count changes, bump this so the "Graduate" achievement still
/// unlocks on the last scenario.
const int kTotalLessonScenarios = 6;

/// Ordered list of achievement definitions. Order drives display order in
/// the grid (oldest first within a tier, tiers sorted by rarity).
///
/// Adding a new entry is safe: the stored [UserStats.unlockedAchievementIds]
/// set uses string IDs, so new definitions simply unlock retroactively next
/// time the user's stats change (and re-evaluation runs).
final List<Achievement> achievementCatalog = [
  // ── Common: "first taste" milestones ──
  Achievement(
    id: 'first_hand',
    title: 'Shuffle Up and Deal',
    description: 'Play your first hand',
    icon: Icons.style_rounded,
    rarity: AchievementRarity.common,
    condition: (s) => s.handsPlayed >= 1,
  ),
  Achievement(
    id: 'first_lesson',
    title: 'Class Is in Session',
    description: 'Complete your first lesson',
    icon: Icons.school_rounded,
    rarity: AchievementRarity.common,
    condition: (s) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'hands_5',
    title: 'Getting Started',
    description: 'Play 5 hands',
    icon: Icons.play_circle_rounded,
    rarity: AchievementRarity.common,
    condition: (s) => s.handsPlayed >= 5,
  ),
  Achievement(
    id: 'streak_3',
    title: 'On a Roll',
    description: 'Maintain a 3-day streak',
    icon: Icons.local_fire_department_rounded,
    rarity: AchievementRarity.common,
    condition: (s) => s.bestStreakDays >= 3,
  ),

  // ── Rare: real commitment ──
  Achievement(
    id: 'hands_25',
    title: 'Regular at the Felt',
    description: 'Play 25 hands',
    icon: Icons.casino_rounded,
    rarity: AchievementRarity.rare,
    condition: (s) => s.handsPlayed >= 25,
  ),
  Achievement(
    id: 'lessons_3',
    title: 'Book Smart',
    description: 'Complete 3 lessons',
    icon: Icons.menu_book_rounded,
    rarity: AchievementRarity.rare,
    condition: (s) => s.lessonsCompleted >= 3,
  ),
  Achievement(
    id: 'level_5',
    title: 'Rising Stakes',
    description: 'Reach level 5',
    icon: Icons.trending_up_rounded,
    rarity: AchievementRarity.rare,
    condition: (s) => s.level >= 5,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week-Long Warrior',
    description: 'Hold a 7-day streak',
    icon: Icons.whatshot_rounded,
    rarity: AchievementRarity.rare,
    condition: (s) => s.bestStreakDays >= 7,
  ),

  // ── Epic: serious grinders ──
  Achievement(
    id: 'hands_100',
    title: 'Centurion',
    description: 'Play 100 hands',
    icon: Icons.military_tech_rounded,
    rarity: AchievementRarity.epic,
    condition: (s) => s.handsPlayed >= 100,
  ),
  Achievement(
    id: 'level_10',
    title: 'Double Digits',
    description: 'Reach level 10',
    icon: Icons.workspace_premium_rounded,
    rarity: AchievementRarity.epic,
    condition: (s) => s.level >= 10,
  ),
  Achievement(
    id: 'all_lessons',
    title: 'Graduate',
    description: 'Finish every lesson in the trainer',
    icon: Icons.school_outlined,
    rarity: AchievementRarity.epic,
    condition: (s) => s.lessonsCompleted >= kTotalLessonScenarios,
  ),

  // ── Legendary: rarefied air ──
  Achievement(
    id: 'streak_30',
    title: 'Iron Discipline',
    description: 'Keep a 30-day streak alive',
    icon: Icons.bolt_rounded,
    rarity: AchievementRarity.legendary,
    condition: (s) => s.bestStreakDays >= 30,
  ),
  Achievement(
    id: 'level_20',
    title: 'High Roller',
    description: 'Reach level 20',
    icon: Icons.diamond_rounded,
    rarity: AchievementRarity.legendary,
    condition: (s) => s.level >= 20,
  ),
];

/// Lookup by id. Returns null when the stored id references a retired
/// achievement — allows forward-compatible serialization.
Achievement? achievementById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}

/// Returns the set of achievement ids whose [Achievement.condition] is true
/// for [stats] but were not present in [alreadyUnlocked]. The result is used
/// by the progression notifier to detect and surface new unlocks.
Set<String> detectNewlyUnlocked(
  UserStats stats,
  Set<String> alreadyUnlocked,
) {
  final newlyUnlocked = <String>{};
  for (final a in achievementCatalog) {
    if (alreadyUnlocked.contains(a.id)) continue;
    if (a.condition(stats)) newlyUnlocked.add(a.id);
  }
  return newlyUnlocked;
}
