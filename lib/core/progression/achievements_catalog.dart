import 'package:flutter/material.dart';

import 'achievement.dart';
import 'user_stats.dart';

/// Hand-rolled achievement catalog. Order here is the render order in the
/// Profile grid (already grouped by category). Append-only — IDs are
/// persisted by name, so removing or renaming an entry would orphan a
/// player's unlock record.
final List<Achievement> achievementsCatalog = [
  // ── Volume ───────────────────────────────────────────────
  Achievement(
    id: AchievementId.firstDeal,
    title: 'First Deal',
    description: 'Play your first hand.',
    icon: Icons.style_rounded,
    category: AchievementCategory.volume,
    threshold: 1,
    currentValue: (s) => s.handsPlayed,
  ),
  Achievement(
    id: AchievementId.gettingComfortable,
    title: 'Getting Comfortable',
    description: 'Play 10 hands.',
    icon: Icons.airline_seat_recline_normal_rounded,
    category: AchievementCategory.volume,
    threshold: 10,
    currentValue: (s) => s.handsPlayed,
  ),
  Achievement(
    id: AchievementId.marathonPlayer,
    title: 'Marathon Player',
    description: 'Play 100 hands.',
    icon: Icons.directions_run_rounded,
    category: AchievementCategory.volume,
    threshold: 100,
    currentValue: (s) => s.handsPlayed,
  ),

  // ── Streak ───────────────────────────────────────────────
  Achievement(
    id: AchievementId.threeOnTheTrot,
    title: 'Three on the Trot',
    description: 'Play 3 days in a row.',
    icon: Icons.local_fire_department_rounded,
    category: AchievementCategory.streak,
    threshold: 3,
    currentValue: (s) => s.bestStreakDays,
  ),
  Achievement(
    id: AchievementId.weekWarrior,
    title: 'Week Warrior',
    description: '7-day streak.',
    icon: Icons.whatshot_rounded,
    category: AchievementCategory.streak,
    threshold: 7,
    currentValue: (s) => s.bestStreakDays,
  ),
  Achievement(
    id: AchievementId.lockedIn,
    title: 'Locked In',
    description: '30-day streak — habit unlocked.',
    icon: Icons.lock_clock_rounded,
    category: AchievementCategory.streak,
    threshold: 30,
    currentValue: (s) => s.bestStreakDays,
  ),

  // ── Mastery ──────────────────────────────────────────────
  Achievement(
    id: AchievementId.eagerStudent,
    title: 'Eager Student',
    description: 'Complete your first lesson.',
    icon: Icons.school_rounded,
    category: AchievementCategory.mastery,
    threshold: 1,
    currentValue: (s) => s.lessonsCompleted,
  ),
  Achievement(
    id: AchievementId.topOfTheClass,
    title: 'Top of the Class',
    description: 'Complete 15 lesson scenarios.',
    icon: Icons.workspace_premium_rounded,
    category: AchievementCategory.mastery,
    threshold: 15,
    currentValue: (s) => s.lessonsCompleted,
  ),
  Achievement(
    id: AchievementId.sharpEye,
    title: 'Sharp Eye',
    description: 'Reach Level 10.',
    icon: Icons.visibility_rounded,
    category: AchievementCategory.mastery,
    threshold: 10,
    currentValue: (s) => s.level,
  ),

  // ── Showdown ─────────────────────────────────────────────
  Achievement(
    id: AchievementId.firstPot,
    title: 'First Pot',
    description: 'Win your first hand.',
    icon: Icons.emoji_events_rounded,
    category: AchievementCategory.showdown,
    threshold: 1,
    currentValue: (s) => s.handsWon,
  ),
  Achievement(
    id: AchievementId.hotHand,
    title: 'Hot Hand',
    description: 'Win 10 hands.',
    icon: Icons.bolt_rounded,
    category: AchievementCategory.showdown,
    threshold: 10,
    currentValue: (s) => s.handsWon,
  ),
  Achievement(
    id: AchievementId.bigWinner,
    title: 'Big Winner',
    description: 'Win 50 hands.',
    icon: Icons.military_tech_rounded,
    category: AchievementCategory.showdown,
    threshold: 50,
    currentValue: (s) => s.handsWon,
  ),
];

/// Pure helper: set of achievement IDs unlocked by [stats], according to the
/// catalog. Independent of any persisted unlock state — the persisted set is
/// just a "we've already celebrated this" marker so the toast doesn't fire
/// twice.
Set<AchievementId> currentlyEarned(UserStats stats) {
  final earned = <AchievementId>{};
  for (final a in achievementsCatalog) {
    if (a.isUnlocked(stats)) earned.add(a.id);
  }
  return earned;
}
