import 'achievement.dart';

/// Canonical list of achievements users can unlock.
///
/// Order matters for the gallery: generally arranged from easiest (Common)
/// to hardest (Legendary). Adding a new entry is non-breaking; ids must
/// never change once shipped, since they're persisted to disk.
final List<Achievement> achievementsCatalog = [
  // ── Hands ──
  Achievement(
    id: 'first_hand',
    title: 'First Hand',
    description: 'Complete your first hand.',
    iconCodePoint: 0xe037, // Icons.play_arrow
    rarity: AchievementRarity.common,
    isUnlocked: (s) => s.handsPlayed >= 1,
  ),
  Achievement(
    id: 'first_win',
    title: 'First Blood',
    description: 'Win your first showdown.',
    iconCodePoint: 0xe3a9, // Icons.emoji_events (trophy)
    rarity: AchievementRarity.common,
    isUnlocked: (s) => s.handsWon >= 1,
  ),
  Achievement(
    id: 'ten_hands',
    title: 'Warming Up',
    description: 'Play 10 hands.',
    iconCodePoint: 0xe8e8, // Icons.shield
    rarity: AchievementRarity.common,
    isUnlocked: (s) => s.handsPlayed >= 10,
  ),
  Achievement(
    id: 'hundred_hands',
    title: 'Century',
    description: 'Play 100 hands.',
    iconCodePoint: 0xe87d, // Icons.trending_up (chart)
    rarity: AchievementRarity.rare,
    isUnlocked: (s) => s.handsPlayed >= 100,
  ),

  // ── Streaks ──
  Achievement(
    id: 'streak_three',
    title: 'Hat Trick',
    description: 'Play 3 days in a row.',
    iconCodePoint: 0xef55, // Icons.local_fire_department_rounded
    rarity: AchievementRarity.common,
    isUnlocked: (s) => s.bestStreakDays >= 3,
  ),
  Achievement(
    id: 'streak_seven',
    title: 'Wildfire',
    description: 'Play 7 days in a row.',
    iconCodePoint: 0xef55, // Icons.local_fire_department_rounded
    rarity: AchievementRarity.rare,
    isUnlocked: (s) => s.bestStreakDays >= 7,
  ),
  Achievement(
    id: 'streak_thirty',
    title: 'Iron Discipline',
    description: 'Play 30 days in a row.',
    iconCodePoint: 0xef55, // Icons.local_fire_department_rounded
    rarity: AchievementRarity.legendary,
    isUnlocked: (s) => s.bestStreakDays >= 30,
  ),

  // ── Lessons ──
  Achievement(
    id: 'first_lesson',
    title: 'Back to School',
    description: 'Complete your first lesson scenario.',
    iconCodePoint: 0xe80c, // Icons.school
    rarity: AchievementRarity.common,
    isUnlocked: (s) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'five_lessons',
    title: 'Scholar',
    description: 'Complete 5 lesson scenarios.',
    iconCodePoint: 0xe80c, // Icons.school
    rarity: AchievementRarity.rare,
    isUnlocked: (s) => s.lessonsCompleted >= 5,
  ),

  // ── Level ──
  Achievement(
    id: 'level_five',
    title: 'Rising Star',
    description: 'Reach level 5.',
    iconCodePoint: 0xe838, // Icons.star
    rarity: AchievementRarity.rare,
    isUnlocked: (s) => s.level >= 5,
  ),
  Achievement(
    id: 'level_ten',
    title: 'Table Captain',
    description: 'Reach level 10.',
    iconCodePoint: 0xe838, // Icons.star
    rarity: AchievementRarity.epic,
    isUnlocked: (s) => s.level >= 10,
  ),
];
