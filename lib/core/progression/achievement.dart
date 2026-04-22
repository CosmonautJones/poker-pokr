import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Broad thematic grouping used for sorting + coloring on the achievements
/// grid. Groups map 1:1 to the categories a player intuitively recognizes:
/// volume, knowledge, consistency, mastery.
enum AchievementGroup {
  grind,      // hands played
  study,      // lessons completed
  streak,     // consistency / days
  mastery,    // XP / level milestones
}

/// Visual tier for an achievement. Drives the card color / border and maps
/// roughly to how hard the target is relative to a casual player.
enum AchievementTier {
  bronze,
  silver,
  gold,
  platinum,
}

/// A single earnable badge with a deterministic unlock predicate.
///
/// The unlock rule is expressed as `progress(stats) >= target`, which makes
/// the same definition serve three UI needs without branching:
///  - boolean unlocked state (completed when progress clears target)
///  - progress bar fill (`progress / target`, clamped to `[0,1]`)
///  - "X / Y" text on the card
///
/// The catalog is intentionally static: achievements don't change between
/// releases, so there's no runtime source of truth to re-sync with. Adding
/// a new achievement is just appending to [AchievementCatalog.all].
@immutable
class Achievement {
  /// Stable identifier used as the key in persisted `unlockedAchievements`.
  /// Never change an id once released — existing unlocks on user devices
  /// would be orphaned.
  final String id;

  final String title;
  final String description;
  final IconData icon;
  final AchievementGroup group;
  final AchievementTier tier;

  /// Target value on the relevant counter (e.g. 10 hands, XP for level 5).
  final int target;

  /// Reads the current progress value from a [UserStats] snapshot.
  final int Function(UserStats stats) progress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.group,
    required this.tier,
    required this.target,
    required this.progress,
  });

  /// True when [stats] satisfies the unlock condition right now.
  bool isUnlockedIn(UserStats stats) => progress(stats) >= target;

  /// Fraction toward unlock in `[0, 1]`. Returns 1.0 once unlocked.
  double progressFraction(UserStats stats) {
    if (target <= 0) return 1.0;
    final raw = progress(stats) / target;
    if (raw.isNaN || raw.isNegative) return 0.0;
    return raw > 1.0 ? 1.0 : raw;
  }
}

/// Canonical list of every achievement shipped with the app.
///
/// Grouped in a roughly easy → hard ordering within each category so the grid
/// reads naturally. Tiers escalate bronze → platinum inside a group.
abstract final class AchievementCatalog {
  static final List<Achievement> all = [
    // ── Grind (hands played) ──
    Achievement(
      id: 'grind_first_hand',
      title: 'Welcome to the Felt',
      description: 'Play your first hand.',
      icon: Icons.play_circle_rounded,
      group: AchievementGroup.grind,
      tier: AchievementTier.bronze,
      target: 1,
      progress: (s) => s.handsPlayed,
    ),
    Achievement(
      id: 'grind_hands_10',
      title: 'Regular',
      description: 'Play 10 hands.',
      icon: Icons.style_rounded,
      group: AchievementGroup.grind,
      tier: AchievementTier.silver,
      target: 10,
      progress: (s) => s.handsPlayed,
    ),
    Achievement(
      id: 'grind_hands_50',
      title: 'Grinder',
      description: 'Play 50 hands.',
      icon: Icons.casino_rounded,
      group: AchievementGroup.grind,
      tier: AchievementTier.gold,
      target: 50,
      progress: (s) => s.handsPlayed,
    ),
    Achievement(
      id: 'grind_hands_200',
      title: 'Rounder',
      description: 'Play 200 hands.',
      icon: Icons.military_tech_rounded,
      group: AchievementGroup.grind,
      tier: AchievementTier.platinum,
      target: 200,
      progress: (s) => s.handsPlayed,
    ),

    // ── Study (lessons completed) ──
    Achievement(
      id: 'study_first_lesson',
      title: 'Student of the Game',
      description: 'Complete your first lesson.',
      icon: Icons.school_rounded,
      group: AchievementGroup.study,
      tier: AchievementTier.bronze,
      target: 1,
      progress: (s) => s.lessonsCompleted,
    ),
    Achievement(
      id: 'study_lessons_5',
      title: 'Apprentice',
      description: 'Complete 5 lessons.',
      icon: Icons.menu_book_rounded,
      group: AchievementGroup.study,
      tier: AchievementTier.silver,
      target: 5,
      progress: (s) => s.lessonsCompleted,
    ),
    Achievement(
      id: 'study_lessons_20',
      title: 'Scholar',
      description: 'Complete 20 lessons.',
      icon: Icons.auto_stories_rounded,
      group: AchievementGroup.study,
      tier: AchievementTier.gold,
      target: 20,
      progress: (s) => s.lessonsCompleted,
    ),

    // ── Streak (consistency) ──
    Achievement(
      id: 'streak_days_3',
      title: 'Back to the Table',
      description: 'Reach a 3-day streak.',
      icon: Icons.local_fire_department_rounded,
      group: AchievementGroup.streak,
      tier: AchievementTier.bronze,
      target: 3,
      progress: (s) => s.bestStreakDays,
    ),
    Achievement(
      id: 'streak_days_7',
      title: 'Week-Long Grind',
      description: 'Reach a 7-day streak.',
      icon: Icons.calendar_month_rounded,
      group: AchievementGroup.streak,
      tier: AchievementTier.silver,
      target: 7,
      progress: (s) => s.bestStreakDays,
    ),
    Achievement(
      id: 'streak_days_30',
      title: 'Habit Formed',
      description: 'Reach a 30-day streak.',
      icon: Icons.whatshot_rounded,
      group: AchievementGroup.streak,
      tier: AchievementTier.platinum,
      target: 30,
      progress: (s) => s.bestStreakDays,
    ),

    // ── Mastery (level / XP) ──
    Achievement(
      id: 'mastery_level_5',
      title: 'Making Moves',
      description: 'Reach level 5.',
      icon: Icons.trending_up_rounded,
      group: AchievementGroup.mastery,
      tier: AchievementTier.silver,
      target: Progression.xpForLevel(5),
      progress: (s) => s.totalXp,
    ),
    Achievement(
      id: 'mastery_level_10',
      title: 'Sharp',
      description: 'Reach level 10.',
      icon: Icons.workspace_premium_rounded,
      group: AchievementGroup.mastery,
      tier: AchievementTier.gold,
      target: Progression.xpForLevel(10),
      progress: (s) => s.totalXp,
    ),
  ];

  /// Total number of achievements in the catalog. Convenience for "X / N".
  static int get totalCount => all.length;

  /// Lookup an achievement by id. Returns `null` for ids not in the catalog
  /// (e.g. stale entries from an older install); callers should skip those
  /// gracefully rather than crashing.
  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }
}

/// Pure-Dart helper that computes the diff between two stats snapshots.
///
/// Consumes a *previous* stats snapshot (with its current `unlockedAchievements`
/// map) and a *next* stats snapshot, and returns the list of achievement ids
/// that crossed their unlock threshold as a result of the transition.
///
/// Guarantees:
///  - Never re-emits an id that is already present in
///    `prev.unlockedAchievements` (idempotent; safe to call repeatedly).
///  - Only considers ids present in [AchievementCatalog.all], so orphaned
///    legacy ids in the persisted map don't leak out.
///  - Preserves catalog order in the returned list so the UI can show the
///    "first" unlock first when multiple trigger on the same event.
abstract final class AchievementEvaluator {
  /// Returns newly unlocked achievement ids for the [prev] → [next] transition.
  static List<String> newlyUnlocked({
    required UserStats prev,
    required UserStats next,
  }) {
    final already = prev.unlockedAchievements.keys.toSet();
    final unlocked = <String>[];
    for (final a in AchievementCatalog.all) {
      if (already.contains(a.id)) continue;
      if (a.isUnlockedIn(next)) unlocked.add(a.id);
    }
    return unlocked;
  }

  /// Returns the set of achievement ids that [stats] already satisfies,
  /// regardless of what's in `stats.unlockedAchievements`. Used once at
  /// install-upgrade time to backfill badges for users who had progression
  /// from before this feature shipped.
  static Set<String> satisfiedIds(UserStats stats) {
    final out = <String>{};
    for (final a in AchievementCatalog.all) {
      if (a.isUnlockedIn(stats)) out.add(a.id);
    }
    return out;
  }
}
