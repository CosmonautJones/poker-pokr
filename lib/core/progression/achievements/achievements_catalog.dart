import 'package:flutter/material.dart';

import '../../../poker/engine/hand_evaluator.dart';
import '../../../poker/models/game_type.dart';
import 'achievement.dart';
import 'achievement_event.dart';

/// The static list of achievements the app exposes.
///
/// Order is the display order on the wall. Add new entries to the end so
/// previously-unlocked positions stay stable for users who memorized them.
final List<Achievement> achievementsCatalog = [
  // ---------------------- Volume ----------------------
  Achievement(
    id: 'play_first_hand',
    title: 'First Deal',
    description: 'Play your first hand.',
    icon: Icons.style_rounded,
    tier: AchievementTier.bronze,
    category: AchievementCategory.volume,
    threshold: 1,
    xpReward: 25,
    progressFn:
        Achievement.counter((e) => e is HandCompletedEvent),
  ),
  Achievement(
    id: 'play_10_hands',
    title: 'In the Game',
    description: 'Play 10 hands.',
    icon: Icons.casino_rounded,
    tier: AchievementTier.bronze,
    category: AchievementCategory.volume,
    threshold: 10,
    xpReward: 50,
    progressFn:
        Achievement.counter((e) => e is HandCompletedEvent),
  ),
  Achievement(
    id: 'play_100_hands',
    title: 'Grinder',
    description: 'Play 100 hands.',
    icon: Icons.local_fire_department_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.volume,
    threshold: 100,
    xpReward: 150,
    progressFn:
        Achievement.counter((e) => e is HandCompletedEvent),
  ),

  // ---------------------- Wins ----------------------
  Achievement(
    id: 'first_win',
    title: 'First Blood',
    description: 'Win a hand.',
    icon: Icons.emoji_events_rounded,
    tier: AchievementTier.bronze,
    category: AchievementCategory.volume,
    threshold: 1,
    xpReward: 25,
    progressFn: Achievement.counter(
      (e) => e is HandCompletedEvent && e.heroWon,
    ),
  ),
  Achievement(
    id: 'win_10',
    title: 'On a Heater',
    description: 'Win 10 hands.',
    icon: Icons.whatshot_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.volume,
    threshold: 10,
    xpReward: 100,
    progressFn: Achievement.counter(
      (e) => e is HandCompletedEvent && e.heroWon,
    ),
  ),
  Achievement(
    id: 'win_50',
    title: 'Crusher',
    description: 'Win 50 hands.',
    icon: Icons.military_tech_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.volume,
    threshold: 50,
    xpReward: 250,
    progressFn: Achievement.counter(
      (e) => e is HandCompletedEvent && e.heroWon,
    ),
  ),

  // ---------------------- Hand mastery ----------------------
  Achievement(
    id: 'win_with_straight',
    title: 'Straight Shooter',
    description: 'Win a hand with a straight.',
    icon: Icons.linear_scale_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.mastery,
    threshold: 1,
    xpReward: 75,
    progressFn: Achievement.counter(
      (e) =>
          e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank == HandRank.straight,
    ),
  ),
  Achievement(
    id: 'win_with_flush',
    title: 'Flush Five',
    description: 'Win a hand with a flush.',
    icon: Icons.water_drop_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.mastery,
    threshold: 1,
    xpReward: 75,
    progressFn: Achievement.counter(
      (e) =>
          e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank == HandRank.flush,
    ),
  ),
  Achievement(
    id: 'win_with_full_house',
    title: 'Full Boat',
    description: 'Win a hand with a full house.',
    icon: Icons.directions_boat_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.mastery,
    threshold: 1,
    xpReward: 125,
    progressFn: Achievement.counter(
      (e) =>
          e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank == HandRank.fullHouse,
    ),
  ),
  Achievement(
    id: 'win_with_quads',
    title: 'Four of a Kind',
    description: 'Win a hand with four of a kind.',
    icon: Icons.dashboard_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.mastery,
    threshold: 1,
    xpReward: 200,
    progressFn: Achievement.counter(
      (e) =>
          e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank == HandRank.fourOfAKind,
    ),
  ),
  Achievement(
    id: 'win_with_straight_flush',
    title: 'Holy Grail',
    description: 'Win a hand with a straight flush.',
    icon: Icons.diamond_rounded,
    tier: AchievementTier.platinum,
    category: AchievementCategory.mastery,
    threshold: 1,
    xpReward: 500,
    progressFn: Achievement.counter(
      (e) =>
          e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank == HandRank.straightFlush,
    ),
  ),

  // ---------------------- Drills ----------------------
  Achievement(
    id: 'lesson_first',
    title: 'Quick Study',
    description: 'Complete your first lesson.',
    icon: Icons.school_rounded,
    tier: AchievementTier.bronze,
    category: AchievementCategory.drills,
    threshold: 1,
    xpReward: 50,
    progressFn:
        Achievement.counter((e) => e is LessonCompletedEvent),
  ),
  Achievement(
    id: 'lesson_5',
    title: 'Student of the Game',
    description: 'Complete 5 lessons.',
    icon: Icons.menu_book_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.drills,
    threshold: 5,
    xpReward: 100,
    progressFn:
        Achievement.counter((e) => e is LessonCompletedEvent),
  ),
  Achievement(
    id: 'lesson_10',
    title: 'Scholar',
    description: 'Complete 10 lessons.',
    icon: Icons.workspace_premium_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.drills,
    threshold: 10,
    xpReward: 200,
    progressFn:
        Achievement.counter((e) => e is LessonCompletedEvent),
  ),

  // ---------------------- Habit ----------------------
  Achievement(
    id: 'streak_3',
    title: 'Warming Up',
    description: 'Play 3 days in a row.',
    icon: Icons.calendar_today_rounded,
    tier: AchievementTier.bronze,
    category: AchievementCategory.habit,
    threshold: 3,
    xpReward: 50,
    progressFn: Achievement.maxOf(
      (e) => e is StreakAdvancedEvent ? e.streakDays : null,
    ),
  ),
  Achievement(
    id: 'streak_7',
    title: 'Week-Long Run',
    description: 'Play 7 days in a row.',
    icon: Icons.event_available_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.habit,
    threshold: 7,
    xpReward: 150,
    progressFn: Achievement.maxOf(
      (e) => e is StreakAdvancedEvent ? e.streakDays : null,
    ),
  ),
  Achievement(
    id: 'streak_30',
    title: 'Iron Discipline',
    description: 'Play 30 days in a row.',
    icon: Icons.bolt_rounded,
    tier: AchievementTier.platinum,
    category: AchievementCategory.habit,
    threshold: 30,
    xpReward: 750,
    progressFn: Achievement.maxOf(
      (e) => e is StreakAdvancedEvent ? e.streakDays : null,
    ),
  ),
  Achievement(
    id: 'level_5',
    title: 'Rising Up',
    description: 'Reach level 5.',
    icon: Icons.trending_up_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.habit,
    threshold: 5,
    xpReward: 100,
    progressFn: Achievement.maxOf(
      (e) => e is LevelReachedEvent ? e.level : null,
    ),
  ),
  Achievement(
    id: 'level_10',
    title: 'Sharp Mind',
    description: 'Reach level 10.',
    icon: Icons.psychology_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.habit,
    threshold: 10,
    xpReward: 300,
    progressFn: Achievement.maxOf(
      (e) => e is LevelReachedEvent ? e.level : null,
    ),
  ),

  // ---------------------- Variety ----------------------
  Achievement(
    id: 'omaha_first',
    title: 'Switch It Up',
    description: 'Play your first Omaha hand.',
    icon: Icons.swap_horiz_rounded,
    tier: AchievementTier.silver,
    category: AchievementCategory.variety,
    threshold: 1,
    xpReward: 75,
    progressFn: Achievement.counter(
      (e) => e is HandCompletedEvent && e.gameType == GameType.omaha,
    ),
  ),
  Achievement(
    id: 'all_in_win',
    title: 'Survived the Shove',
    description: 'Win a hand after going all-in.',
    icon: Icons.flash_on_rounded,
    tier: AchievementTier.gold,
    category: AchievementCategory.variety,
    threshold: 1,
    xpReward: 150,
    progressFn: Achievement.counter(
      (e) => e is HandCompletedEvent && e.heroWon && e.heroWasAllIn,
    ),
  ),
];

/// Lookup by id (rare path; the catalog is small enough for linear scans
/// during normal awarding).
Achievement? achievementById(String id) {
  for (final a in achievementsCatalog) {
    if (a.id == id) return a;
  }
  return null;
}
