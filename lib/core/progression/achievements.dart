/// Achievement / Trophy domain.
///
/// Pure Dart — defines the catalog of achievable badges, their unlock
/// criteria, and an evaluator that derives progress from a [UserStats]
/// snapshot. Persistence (which ones the player has already unlocked) is
/// stored on [UserStats] itself, so this file stays Flutter-free.
library;

import 'scenario_mastery.dart';
import 'user_stats.dart';

/// Stable identifiers for each achievement. Stored as strings on disk so the
/// underlying enum order can change without invalidating prior unlocks.
enum AchievementId {
  firstHand,
  scholar,
  marathon,
  streakWeek,
  streakMonth,
  perfectionist,
  graduate,
  level5,
  level10,
  champion,
}

extension AchievementIdSerialize on AchievementId {
  /// Disk-safe key. We use the enum [name] which is stable across reorderings.
  String get key => name;

  static AchievementId? tryParse(String raw) {
    for (final v in AchievementId.values) {
      if (v.name == raw) return v;
    }
    return null;
  }
}

/// Snapshot of how close the player is to unlocking a specific achievement.
class AchievementProgress {
  final int current;
  final int target;

  const AchievementProgress({required this.current, required this.target});

  bool get isUnlocked => current >= target && target > 0;

  double get fraction {
    if (target <= 0) return 0;
    if (current >= target) return 1;
    return current / target;
  }
}

/// Static metadata for one achievement.
class Achievement {
  final AchievementId id;
  final String title;
  final String description;
  final int iconCodePoint;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
  });

  /// Lookup helper.
  static Achievement byId(AchievementId id) =>
      achievementsCatalog.firstWhere((a) => a.id == id);
}

/// Curated catalog. Order here = display order in the trophy cabinet.
const List<Achievement> achievementsCatalog = [
  Achievement(
    id: AchievementId.firstHand,
    title: 'First Hand',
    description: 'Play your first hand at the table.',
    iconCodePoint: 0xe037, // play_arrow_rounded
  ),
  Achievement(
    id: AchievementId.scholar,
    title: 'Scholar',
    description: 'Complete your first lesson scenario.',
    iconCodePoint: 0xe559, // school_rounded
  ),
  Achievement(
    id: AchievementId.perfectionist,
    title: 'Perfectionist',
    description: '3-star a single scenario by completing it cleanly 3 times.',
    iconCodePoint: 0xe838, // star_rounded
  ),
  Achievement(
    id: AchievementId.graduate,
    title: 'Graduate',
    description: '3-star every scenario in a single lesson.',
    iconCodePoint: 0xea77, // workspace_premium_rounded
  ),
  Achievement(
    id: AchievementId.streakWeek,
    title: 'On Fire',
    description: 'Hit a 7-day play streak.',
    iconCodePoint: 0xef55, // local_fire_department_rounded
  ),
  Achievement(
    id: AchievementId.streakMonth,
    title: 'Iron Discipline',
    description: 'Hit a 30-day play streak.',
    iconCodePoint: 0xe8e8, // shield_rounded
  ),
  Achievement(
    id: AchievementId.level5,
    title: 'Rising Star',
    description: 'Reach Level 5.',
    iconCodePoint: 0xe838, // star_rounded
  ),
  Achievement(
    id: AchievementId.level10,
    title: 'High Roller',
    description: 'Reach Level 10.',
    iconCodePoint: 0xea70, // diamond_rounded
  ),
  Achievement(
    id: AchievementId.marathon,
    title: 'Marathoner',
    description: 'Play 50 hands.',
    iconCodePoint: 0xe87d, // trending_up_rounded
  ),
  Achievement(
    id: AchievementId.champion,
    title: 'Champion',
    description: 'Win 25 hands.',
    iconCodePoint: 0xea64, // emoji_events_rounded (trophy)
  ),
];

/// Total stars earnable across all known scenarios. Used for "completion %".
int totalStarsAvailable(int totalScenarios) => totalScenarios * 3;

/// Sums [bestStars] across the player's mastery map.
int starsEarnedFromMastery(Map<String, MasteryRecord> mastery) {
  var total = 0;
  for (final r in mastery.values) {
    total += r.bestStars;
  }
  return total;
}

/// Pure evaluator: given a stats snapshot and the static catalog dimensions,
/// computes per-achievement progress and the freshly-unlocked set.
///
/// A [disabled] singleton is provided for tests and code paths that want
/// to opt out of achievement evaluation entirely (no unlocks, no XP
/// bonuses). The default Riverpod binding uses [disabled] so unrelated
/// tests don't have to think about achievements; `main.dart` overrides
/// with a live evaluator wired against the lessons catalog.
class AchievementEvaluator {
  /// Total scenarios known to the app, used for full-coverage achievements.
  final int totalScenarios;

  /// Optional mapping of lessonId -> set of scenario keys for that lesson.
  /// Lets [Graduate] check whether any single lesson is fully 3-starred.
  final Map<String, List<String>> scenarioKeysByLesson;

  /// Internal flag: when false, the evaluator reports no progress and no
  /// unlocks. Lets us provide a safe default without changing the public
  /// API.
  final bool _enabled;

  const AchievementEvaluator({
    required this.totalScenarios,
    required this.scenarioKeysByLesson,
  }) : _enabled = true;

  const AchievementEvaluator._disabled()
      : totalScenarios = 0,
        scenarioKeysByLesson = const {},
        _enabled = false;

  /// Inert evaluator that reports no progress and unlocks nothing.
  static const AchievementEvaluator disabled =
      AchievementEvaluator._disabled();

  /// Whether this evaluator returns live data; consumers can branch UI on
  /// this if they want to hide trophy widgets entirely.
  bool get isEnabled => _enabled;

  /// Compute progress for [id] given [stats].
  AchievementProgress progress(AchievementId id, UserStats stats) {
    if (!_enabled) {
      return const AchievementProgress(current: 0, target: 0);
    }
    switch (id) {
      case AchievementId.firstHand:
        return AchievementProgress(
          current: stats.handsPlayed.clamp(0, 1),
          target: 1,
        );
      case AchievementId.scholar:
        return AchievementProgress(
          current: stats.lessonsCompleted.clamp(0, 1),
          target: 1,
        );
      case AchievementId.marathon:
        return AchievementProgress(
          current: stats.handsPlayed.clamp(0, 50),
          target: 50,
        );
      case AchievementId.champion:
        return AchievementProgress(
          current: stats.handsWon.clamp(0, 25),
          target: 25,
        );
      case AchievementId.streakWeek:
        return AchievementProgress(
          current: stats.bestStreakDays.clamp(0, 7),
          target: 7,
        );
      case AchievementId.streakMonth:
        return AchievementProgress(
          current: stats.bestStreakDays.clamp(0, 30),
          target: 30,
        );
      case AchievementId.level5:
        return AchievementProgress(
          current: stats.level.clamp(0, 5),
          target: 5,
        );
      case AchievementId.level10:
        return AchievementProgress(
          current: stats.level.clamp(0, 10),
          target: 10,
        );
      case AchievementId.perfectionist:
        var maxStars = 0;
        for (final r in stats.scenarioMastery.values) {
          if (r.bestStars > maxStars) maxStars = r.bestStars;
        }
        return AchievementProgress(
          current: maxStars.clamp(0, 3),
          target: 3,
        );
      case AchievementId.graduate:
        // Best lesson coverage: max # of fully-3-starred scenarios in any
        // single lesson, normalized against that lesson's scenario count.
        var bestRatioCurrent = 0;
        var bestRatioTarget = 1;
        for (final entry in scenarioKeysByLesson.entries) {
          final keys = entry.value;
          if (keys.isEmpty) continue;
          var threeStars = 0;
          for (final k in keys) {
            final rec = stats.scenarioMastery[k];
            if (rec != null && rec.bestStars >= 3) threeStars += 1;
          }
          // Pick the lesson the player is closest to graduating from.
          if (threeStars * bestRatioTarget >= bestRatioCurrent * keys.length) {
            bestRatioCurrent = threeStars;
            bestRatioTarget = keys.length;
          }
        }
        return AchievementProgress(
          current: bestRatioCurrent,
          target: bestRatioTarget,
        );
    }
  }

  /// Returns the set of [AchievementId]s currently unlocked given [stats].
  Set<AchievementId> unlockedSet(UserStats stats) {
    if (!_enabled) return const {};
    final set = <AchievementId>{};
    for (final id in AchievementId.values) {
      if (progress(id, stats).isUnlocked) set.add(id);
    }
    return set;
  }

  /// Compute the IDs that would transition from "locked" to "unlocked" if
  /// [stats] is now the latest snapshot vs. the stored
  /// [UserStats.unlockedAchievementIds] set.
  List<AchievementId> newlyUnlocked(UserStats stats) {
    final fresh = unlockedSet(stats);
    final priorRaw = stats.unlockedAchievementIds;
    final fresh2 = <AchievementId>[];
    for (final id in fresh) {
      if (!priorRaw.contains(id.key)) fresh2.add(id);
    }
    return fresh2;
  }
}
