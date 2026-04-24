import 'user_stats.dart';

/// Rarity tier for visual treatment + ordering in the gallery.
enum AchievementRarity {
  common('Common'),
  rare('Rare'),
  epic('Epic'),
  legendary('Legendary');

  final String label;
  const AchievementRarity(this.label);
}

/// An achievement is a named milestone the player can unlock by meeting
/// some condition over their [UserStats].
///
/// Pure Dart: no Flutter imports so this can be unit-tested in isolation.
/// The icon is stored as a Material Icons codePoint; a presentation-layer
/// helper maps it back to a tree-shakable [IconData] (see
/// `achievements_catalog_icons.dart`). This mirrors the same pattern used
/// by [Lesson.iconCodePoint].
class Achievement {
  /// Stable identifier — persisted in [UserStats.unlockedAchievementIds].
  final String id;

  /// Human-readable title shown on cards / toasts.
  final String title;

  /// One-line description of the unlock requirement / flavor.
  final String description;

  /// Material Icons code point.
  final int iconCodePoint;

  /// Rarity tier; drives color + sort order in the gallery.
  final AchievementRarity rarity;

  /// Predicate evaluated against the latest [UserStats]. Returns `true` when
  /// the player has earned the achievement.
  final bool Function(UserStats stats) isUnlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.rarity,
    required this.isUnlocked,
  });
}

/// Pure helper that diffs two stat snapshots and returns the set of
/// achievement ids that transitioned from locked → unlocked.
///
/// Never returns ids that were already unlocked before — so callers can
/// trust the result for one-shot toasts and notifications.
Set<String> newlyUnlockedAchievements({
  required UserStats before,
  required UserStats after,
  required List<Achievement> catalog,
}) {
  final out = <String>{};
  for (final a in catalog) {
    if (before.unlockedAchievementIds.contains(a.id)) continue;
    if (a.isUnlocked(after)) {
      out.add(a.id);
    }
  }
  return out;
}
