import 'package:flutter/material.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Shared visual treatment for an achievement tier — gradient + accent color.
class TierStyle {
  final List<Color> gradient;
  final Color accent;
  final String label;

  const TierStyle({
    required this.gradient,
    required this.accent,
    required this.label,
  });

  static TierStyle of(BuildContext context, AchievementTier tier) {
    final pt = context.poker;
    return switch (tier) {
      AchievementTier.bronze => TierStyle(
          gradient: const [Color(0xFF8D5524), Color(0xFFCD7F32)],
          accent: const Color(0xFFCD7F32),
          label: 'Bronze',
        ),
      AchievementTier.silver => TierStyle(
          gradient: const [Color(0xFF6E7780), Color(0xFFC0C0C0)],
          accent: const Color(0xFFC0C0C0),
          label: 'Silver',
        ),
      AchievementTier.gold => TierStyle(
          gradient: [pt.goldDark, pt.goldPrimary],
          accent: pt.goldPrimary,
          label: 'Gold',
        ),
      AchievementTier.platinum => TierStyle(
          gradient: const [Color(0xFF8E9EAB), Color(0xFFEEF2F3)],
          accent: const Color(0xFFE0E5EC),
          label: 'Platinum',
        ),
    };
  }
}

/// Round medallion icon used by the toast and gallery. Goes muted/silhouette
/// when [unlocked] is false.
class AchievementMedallion extends StatelessWidget {
  final AchievementDef def;
  final bool unlocked;
  final double size;

  const AchievementMedallion({
    super.key,
    required this.def,
    required this.unlocked,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final style = TierStyle.of(context, def.tier);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? LinearGradient(
                colors: style.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: unlocked ? null : pt.surfaceDim,
        border: Border.all(
          color: unlocked
              ? style.accent.withValues(alpha: 0.7)
              : pt.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: style.accent.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(
        unlocked ? def.icon : Icons.lock_outline_rounded,
        size: size * 0.5,
        color: unlocked
            ? Colors.white
            : pt.textMuted.withValues(alpha: 0.45),
      ),
    );
  }
}

String categoryLabel(AchievementCategory c) => switch (c) {
      AchievementCategory.milestone => 'Milestones',
      AchievementCategory.streak => 'Streaks',
      AchievementCategory.mastery => 'Mastery',
      AchievementCategory.discovery => 'Discovery',
    };
