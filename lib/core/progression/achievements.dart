import 'package:flutter/material.dart';

import '../theme/poker_theme.dart';
import 'achievement_state.dart';
import 'user_stats.dart';

enum AchievementTier { bronze, silver, gold }

/// Resolve the visual color for a tier. Bronze and silver are intentional
/// fixed values so unlocked tiers read consistently regardless of theme;
/// gold defers to the active [PokerTheme] gold token.
Color tierColorOf(BuildContext context, AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return const Color(0xFFCD7F32);
    case AchievementTier.silver:
      return const Color(0xFFC0C0C0);
    case AchievementTier.gold:
      return context.poker.goldPrimary;
  }
}

/// Pure description of a single unlockable achievement.
///
/// Defined as a value type so the catalog can be enumerated, evaluated, and
/// rendered without any persistence or Riverpod dependencies.
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementTier tier;
  final int target;
  final int Function(UserStats stats) progress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.tier,
    required this.target,
    required this.progress,
  });

  bool isUnlocked(UserStats stats) => progress(stats) >= target;

  int progressValue(UserStats stats) {
    final v = progress(stats);
    return v > target ? target : v;
  }

  double progressFraction(UserStats stats) {
    if (target <= 0) return 0;
    return (progress(stats) / target).clamp(0.0, 1.0).toDouble();
  }

  /// Returns the ids of every achievement currently unlocked by [stats].
  static List<String> evaluateAll(UserStats stats) {
    final out = <String>[];
    for (final a in kAchievements) {
      if (a.isUnlocked(stats)) out.add(a.id);
    }
    return out;
  }

  /// Lookup by id. Returns null if the id is not in the catalog.
  static Achievement? byId(String id) {
    for (final a in kAchievements) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Pick the most "hooked" locked achievement to surface as a hint.
  ///
  /// Prefers the locked achievement with the highest non-zero progress
  /// fraction; falls back to the lowest-target locked achievement when
  /// nothing has any progress yet. Returns null when every achievement is
  /// already unlocked.
  static Achievement? pickNext(UserStats stats, AchievementState state) {
    final locked = <Achievement>[];
    for (final a in kAchievements) {
      if (!state.isUnlocked(a.id)) locked.add(a);
    }
    if (locked.isEmpty) return null;

    Achievement? best;
    double bestFraction = -1;
    for (final a in locked) {
      final f = a.progressFraction(stats);
      if (f > 0 && f > bestFraction) {
        bestFraction = f;
        best = a;
      }
    }
    if (best != null) return best;

    locked.sort((a, b) => a.target.compareTo(b.target));
    return locked.first;
  }
}

// Use bestStreakDays so once-earned streak achievements don't relock
// when the active streak breaks.
final List<Achievement> kAchievements = [
  Achievement(
    id: 'first_hand',
    title: 'First Hand',
    description: 'Complete your first hand.',
    icon: Icons.flag_rounded,
    tier: AchievementTier.bronze,
    target: 1,
    progress: (s) => s.handsPlayed,
  ),
  Achievement(
    id: 'ten_hands',
    title: 'Sharpening Up',
    description: 'Play 10 hands.',
    icon: Icons.style_rounded,
    tier: AchievementTier.bronze,
    target: 10,
    progress: (s) => s.handsPlayed,
  ),
  Achievement(
    id: 'hundred_hands',
    title: 'Hundred Club',
    description: 'Play 100 hands.',
    icon: Icons.casino_rounded,
    tier: AchievementTier.silver,
    target: 100,
    progress: (s) => s.handsPlayed,
  ),
  Achievement(
    id: 'five_hundred_hands',
    title: 'Grinder',
    description: 'Play 500 hands.',
    icon: Icons.workspace_premium_rounded,
    tier: AchievementTier.gold,
    target: 500,
    progress: (s) => s.handsPlayed,
  ),
  Achievement(
    id: 'first_lesson',
    title: 'Student of the Game',
    description: 'Complete your first lesson.',
    icon: Icons.menu_book_rounded,
    tier: AchievementTier.bronze,
    target: 1,
    progress: (s) => s.lessonsCompleted,
  ),
  Achievement(
    id: 'five_lessons',
    title: 'Apprentice',
    description: 'Complete 5 lessons.',
    icon: Icons.school_rounded,
    tier: AchievementTier.bronze,
    target: 5,
    progress: (s) => s.lessonsCompleted,
  ),
  Achievement(
    id: 'twenty_five_lessons',
    title: 'Lesson Master',
    description: 'Complete 25 lessons.',
    icon: Icons.psychology_rounded,
    tier: AchievementTier.gold,
    target: 25,
    progress: (s) => s.lessonsCompleted,
  ),
  Achievement(
    id: 'level_2',
    title: 'Level Up',
    description: 'Reach level 2.',
    icon: Icons.trending_up_rounded,
    tier: AchievementTier.bronze,
    target: 2,
    progress: (s) => s.level,
  ),
  Achievement(
    id: 'level_5',
    title: 'Rising Star',
    description: 'Reach level 5.',
    icon: Icons.star_rounded,
    tier: AchievementTier.silver,
    target: 5,
    progress: (s) => s.level,
  ),
  Achievement(
    id: 'level_10',
    title: 'Veteran',
    description: 'Reach level 10.',
    icon: Icons.military_tech_rounded,
    tier: AchievementTier.gold,
    target: 10,
    progress: (s) => s.level,
  ),
  Achievement(
    id: 'streak_3',
    title: 'On Fire',
    description: 'Play on 3 days in a row.',
    icon: Icons.local_fire_department_rounded,
    tier: AchievementTier.bronze,
    target: 3,
    progress: (s) => s.bestStreakDays,
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week Strong',
    description: 'Play on 7 days in a row.',
    icon: Icons.whatshot_rounded,
    tier: AchievementTier.silver,
    target: 7,
    progress: (s) => s.bestStreakDays,
  ),
];
