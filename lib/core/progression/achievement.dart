import 'package:flutter/material.dart';

import '../theme/poker_theme.dart';
import 'user_stats.dart';

/// Rarity tier for an [Achievement]. Drives color, glow, and sort order in
/// the UI; has no effect on XP or gameplay.
enum AchievementRarity {
  common,
  rare,
  epic,
  legendary;

  /// Display label used in the unlock toast and detail sheet.
  String get label => switch (this) {
        AchievementRarity.common => 'Common',
        AchievementRarity.rare => 'Rare',
        AchievementRarity.epic => 'Epic',
        AchievementRarity.legendary => 'Legendary',
      };

  /// Single source of truth for rarity → theme-color mapping. Used by the
  /// tile, the unlock toast, and the detail sheet so they can never drift.
  Color color(PokerTheme pt) => switch (this) {
        AchievementRarity.common => pt.seatActiveBorder,
        AchievementRarity.rare => pt.accent,
        AchievementRarity.epic => pt.straddlePrimary,
        AchievementRarity.legendary => pt.goldPrimary,
      };
}

/// A single achievement definition. [condition] is a pure predicate over a
/// [UserStats] snapshot — evaluated after every stat mutation to detect a
/// newly-unlocked achievement. Definitions are declared once in
/// [achievementCatalog] and are themselves const-friendly (function refs).
@immutable
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final AchievementRarity rarity;

  /// Pure predicate. Must only read from the passed [UserStats] so results
  /// are deterministic and testable.
  final bool Function(UserStats) condition;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.condition,
  });

  /// Equality by id — the catalog guarantees ids are unique, so listeners
  /// comparing `List<Achievement>` for diff purposes don't spuriously
  /// re-fire just because two builds produced distinct instances.
  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Achievement && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
