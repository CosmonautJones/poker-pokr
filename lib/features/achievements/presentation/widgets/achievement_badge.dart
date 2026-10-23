import 'package:flutter/material.dart';

import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Square badge tile rendered in the achievements grid.
///
/// Two visual states keyed off [unlocked]:
///   - locked → desaturated outline with a small lock corner overlay
///   - unlocked → gold gradient fill with a subtle glow
///
/// The badge is purely presentational; tap handling is owned by the parent
/// (the achievements screen wraps each tile in an InkWell that opens a
/// detail sheet).
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const AchievementBadge({
    super.key,
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    const iconSize = 32.0;
    const iconBoxSize = 60.0;

    final iconBox = Container(
      width: iconBoxSize,
      height: iconBoxSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: unlocked
            ? RadialGradient(
                colors: [
                  pt.goldLight,
                  pt.goldPrimary,
                  pt.goldDark,
                ],
                stops: const [0.0, 0.6, 1.0],
              )
            : null,
        color: unlocked ? null : pt.surfaceDim,
        border: Border.all(
          color: unlocked
              ? pt.goldLight.withValues(alpha: 0.7)
              : pt.borderSubtle.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: unlocked
            ? [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      alignment: Alignment.center,
      child: Icon(
        achievement.icon,
        size: iconSize,
        color: unlocked
            ? Colors.white
            : pt.textMuted.withValues(alpha: 0.55),
      ),
    );

    final title = Text(
      achievement.title,
      style: textTheme.labelMedium?.copyWith(
        color: unlocked
            ? Colors.white
            : pt.textMuted.withValues(alpha: 0.7),
        fontWeight: FontWeight.w700,
      ),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: pt.surfaceDim.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: unlocked
                  ? pt.goldPrimary.withValues(alpha: 0.45)
                  : pt.borderSubtle.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              iconBox,
              const SizedBox(height: 10),
              title,
            ],
          ),
        ),
        if (!unlocked)
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_rounded,
                size: 12,
                color: pt.textMuted,
              ),
            ),
          ),
      ],
    );
  }
}
