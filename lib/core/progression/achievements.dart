/// Pure-Dart achievement catalog and unlock evaluator.
///
/// Keeps Flutter and storage out of scope so unit tests can run on the
/// VM. The notifier diffs the previous unlocked set against the result of
/// [evaluateUnlockedIds] to find newly-earned ids.
library;

import 'user_stats.dart';

/// Category buckets used purely for visual grouping in the profile grid.
enum AchievementTier { bronze, silver, gold }

/// Static metadata about a single achievement.
class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementTier tier;

  /// String key looked up in `achievement_icons.dart` to obtain a const
  /// [IconData]. Stored as a key (not [IconData]) so this catalog stays
  /// Flutter-free and unit-testable on the VM. Required for Flutter's
  /// icon tree-shaker, which only handles const IconData references.
  final String iconKey;

  /// Predicate that decides whether the player has earned this achievement
  /// given the latest [UserStats] snapshot. Pure — no IO.
  final bool Function(UserStats stats) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.tier,
    required this.iconKey,
    required this.isUnlocked,
  });
}

/// All achievements in display order. Stable order is important because the
/// profile grid renders this list directly; reordering would shuffle the
/// grid for existing users.
final List<Achievement> achievementCatalog = [
  // ── First steps ─────────────────────────────────────────────────────────
  Achievement(
    id: 'first_hand',
    title: 'Welcome Aboard',
    description: 'Play your first hand.',
    tier: AchievementTier.bronze,
    iconKey: 'play_arrow',
    isUnlocked: (s) => s.handsPlayed >= 1,
  ),
  Achievement(
    id: 'first_lesson',
    title: 'Student of the Game',
    description: 'Finish your first lesson scenario.',
    tier: AchievementTier.bronze,
    iconKey: 'school',
    isUnlocked: (s) => s.lessonsCompleted >= 1,
  ),
  Achievement(
    id: 'first_win',
    title: 'First Blood',
    description: 'Win your first showdown as the hero.',
    tier: AchievementTier.bronze,
    iconKey: 'trophy',
    isUnlocked: (s) => s.lifetimeWins >= 1,
  ),

  // ── Volume: hands ───────────────────────────────────────────────────────
  Achievement(
    id: 'hands_10',
    title: 'Tens Player',
    description: 'Play 10 hands.',
    tier: AchievementTier.bronze,
    iconKey: 'bar_chart',
    isUnlocked: (s) => s.handsPlayed >= 10,
  ),
  Achievement(
    id: 'hands_50',
    title: 'Half a Hundred',
    description: 'Play 50 hands.',
    tier: AchievementTier.silver,
    iconKey: 'insights',
    isUnlocked: (s) => s.handsPlayed >= 50,
  ),
  Achievement(
    id: 'hands_250',
    title: 'Regular',
    description: 'Play 250 hands.',
    tier: AchievementTier.gold,
    iconKey: 'workspace_premium',
    isUnlocked: (s) => s.handsPlayed >= 250,
  ),

  // ── Streaks ─────────────────────────────────────────────────────────────
  Achievement(
    id: 'streak_3',
    title: 'Habit Forming',
    description: 'Reach a 3-day streak.',
    tier: AchievementTier.bronze,
    iconKey: 'fire',
    isUnlocked: (s) => s.bestStreakDays >= 3,
  ),
  Achievement(
    id: 'streak_7',
    title: 'On the Rail',
    description: 'Reach a 7-day streak.',
    tier: AchievementTier.silver,
    iconKey: 'fire',
    isUnlocked: (s) => s.bestStreakDays >= 7,
  ),
  Achievement(
    id: 'streak_30',
    title: 'Grinder',
    description: 'Reach a 30-day streak.',
    tier: AchievementTier.gold,
    iconKey: 'fire',
    isUnlocked: (s) => s.bestStreakDays >= 30,
  ),

  // ── Lessons ─────────────────────────────────────────────────────────────
  Achievement(
    id: 'lessons_3',
    title: 'Curious Mind',
    description: 'Complete 3 lessons.',
    tier: AchievementTier.bronze,
    iconKey: 'school',
    isUnlocked: (s) => s.lessonsCompleted >= 3,
  ),
  Achievement(
    id: 'lessons_10',
    title: 'Bookworm',
    description: 'Complete 10 lessons.',
    tier: AchievementTier.silver,
    iconKey: 'menu_book',
    isUnlocked: (s) => s.lessonsCompleted >= 10,
  ),

  // ── Levels (XP curve milestones) ────────────────────────────────────────
  Achievement(
    id: 'level_5',
    title: 'Sharp Stack',
    description: 'Reach level 5.',
    tier: AchievementTier.silver,
    iconKey: 'star',
    isUnlocked: (s) => s.level >= 5,
  ),
  Achievement(
    id: 'level_10',
    title: 'Polished Pro',
    description: 'Reach level 10.',
    tier: AchievementTier.gold,
    iconKey: 'star',
    isUnlocked: (s) => s.level >= 10,
  ),

  // ── Daily challenge ─────────────────────────────────────────────────────
  Achievement(
    id: 'daily_5',
    title: 'Five Strong',
    description: 'Complete 5 daily challenges.',
    tier: AchievementTier.silver,
    iconKey: 'calendar',
    isUnlocked: (s) => s.dailyChallengesCompleted >= 5,
  ),
];

/// Lookup helper by id. Returns null if no such id exists; callers should
/// treat unknown ids as legacy/removed and skip them.
Achievement? findAchievementById(String id) {
  for (final a in achievementCatalog) {
    if (a.id == id) return a;
  }
  return null;
}

/// Pure evaluator: returns the set of achievement ids that should be
/// unlocked given [stats], in catalog order. Unknown stale ids in
/// [stats.unlockedAchievements] are intentionally not preserved here —
/// the notifier merges new unlocks into the persisted list and trims
/// stale entries during writes.
List<String> evaluateUnlockedIds(UserStats stats) {
  final out = <String>[];
  for (final a in achievementCatalog) {
    if (a.isUnlocked(stats)) out.add(a.id);
  }
  return out;
}

/// Diff helper used by the notifier. Returns ids that are in [next] but not
/// in [prev], in catalog order. Stable across calls.
List<String> newlyUnlocked(List<String> prev, List<String> next) {
  final prevSet = prev.toSet();
  return [for (final id in next) if (!prevSet.contains(id)) id];
}
