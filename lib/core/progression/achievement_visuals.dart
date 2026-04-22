import 'package:flutter/material.dart';

import '../theme/poker_theme.dart';
import 'achievement.dart';

/// Visual helpers for rendering achievements. Kept separate from
/// `achievement.dart` so the domain layer stays free of `BuildContext` and
/// Material imports beyond [IconData].
extension AchievementTierVisuals on AchievementTier {
  /// Theme-aware color used for borders, glows, and icon tint.
  Color displayColor(PokerTheme pt) {
    switch (this) {
      case AchievementTier.bronze:
        return const Color(0xFFCD7F32);
      case AchievementTier.silver:
        return const Color(0xFFC0C0C0);
      case AchievementTier.gold:
        return pt.goldPrimary;
      case AchievementTier.platinum:
        return const Color(0xFFB9F2FF);
    }
  }

  String get label {
    switch (this) {
      case AchievementTier.bronze:
        return 'Bronze';
      case AchievementTier.silver:
        return 'Silver';
      case AchievementTier.gold:
        return 'Gold';
      case AchievementTier.platinum:
        return 'Platinum';
    }
  }
}

extension AchievementGroupVisuals on AchievementGroup {
  String get label {
    switch (this) {
      case AchievementGroup.grind:
        return 'Grind';
      case AchievementGroup.study:
        return 'Study';
      case AchievementGroup.streak:
        return 'Streak';
      case AchievementGroup.mastery:
        return 'Mastery';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementGroup.grind:
        return Icons.casino_rounded;
      case AchievementGroup.study:
        return Icons.school_rounded;
      case AchievementGroup.streak:
        return Icons.local_fire_department_rounded;
      case AchievementGroup.mastery:
        return Icons.workspace_premium_rounded;
    }
  }
}
