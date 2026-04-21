import 'package:flutter/material.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single achievement cell in the progression grid. Taps open a bottom sheet
/// with the full description and rarity/state context.
class AchievementTile extends ConsumerWidget {
  final Achievement achievement;
  final bool unlocked;

  const AchievementTile({
    super.key,
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final color = achievement.rarity.color(pt);
    final borderAlpha = unlocked ? 0.55 : 0.18;
    final bgAlpha = unlocked ? 0.10 : 0.04;

    return Semantics(
      button: true,
      hint: 'Opens achievement details.',
      label: unlocked
          ? '${achievement.title}, ${achievement.rarity.label} achievement, '
              'unlocked. ${achievement.description}.'
          : '${achievement.title}, ${achievement.rarity.label} achievement, '
              'locked. ${achievement.description}.',
      child: InkWell(
        onTap: () {
          ref.read(hapticServiceProvider).selection();
          _showDetailSheet(context, achievement, unlocked, color);
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: bgAlpha),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: color.withValues(alpha: borderAlpha),
              width: 1,
            ),
            boxShadow: unlocked
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: unlocked ? 0.35 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: color.withValues(
                            alpha: unlocked ? 0.75 : 0.25),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      unlocked ? achievement.icon : Icons.lock_outline_rounded,
                      size: 22,
                      color: unlocked
                          ? color
                          : pt.textMuted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: unlocked
                          ? Colors.white
                          : pt.textMuted.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                achievement.rarity.label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: unlocked
                          ? color
                          : pt.textMuted.withValues(alpha: 0.55),
                      letterSpacing: 1.2,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showDetailSheet(
  BuildContext context,
  Achievement achievement,
  bool unlocked,
  Color color,
) {
  final pt = PokerTheme.of(context);
  final textTheme = Theme.of(context).textTheme;
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: pt.surfaceDim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          color.withValues(alpha: unlocked ? 0.35 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: color.withValues(
                            alpha: unlocked ? 0.75 : 0.25),
                        width: 1.4,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      unlocked ? achievement.icon : Icons.lock_outline_rounded,
                      size: 26,
                      color: unlocked
                          ? color
                          : pt.textMuted.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unlocked
                              ? '${achievement.rarity.label} • Unlocked'
                              : '${achievement.rarity.label} • Locked',
                          style: textTheme.labelMedium?.copyWith(
                            color: unlocked ? color : pt.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                achievement.description,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
