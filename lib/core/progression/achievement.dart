import 'package:flutter/material.dart';

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
}
