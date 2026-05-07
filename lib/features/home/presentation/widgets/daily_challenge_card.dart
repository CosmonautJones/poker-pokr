import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/daily_challenge.dart';
import 'package:poker_trainer/core/progression/daily_challenge_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Compact home-screen surface for the daily challenge: title, progress bar,
/// and reward pill. Hidden on first run (no hands or lessons recorded).
class DailyChallengeCard extends ConsumerWidget {
  const DailyChallengeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(userStatsProvider);
    final challenge = ref.watch(dailyChallengeProvider);

    // First-run: keep the home screen calm.
    if (stats.handsPlayed == 0 && stats.lessonsCompleted == 0) {
      return const SizedBox.shrink();
    }

    final template = ChallengeAlgorithm.findTemplate(challenge.templateId) ??
        ChallengeAlgorithm.templateForDay(DateTime.now());
    final progress = challenge.progress.clamp(0, template.target);
    final fraction = template.target == 0
        ? 0.0
        : (progress / template.target).clamp(0.0, 1.0).toDouble();
    final completed = challenge.completed;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: completed
              ? pt.profit.withValues(alpha: 0.45)
              : pt.goldPrimary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: completed
                ? [
                    pt.profit.withValues(alpha: 0.16),
                    Colors.transparent,
                  ]
                : [
                    pt.goldPrimary.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        (completed ? pt.profit : pt.goldPrimary)
                            .withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: (completed ? pt.profit : pt.goldPrimary)
                          .withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    completed
                        ? Icons.check_rounded
                        : Icons.flag_rounded,
                    size: 20,
                    color: completed ? pt.profit : pt.goldPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Challenge',
                            style: textTheme.labelSmall?.copyWith(
                              color: pt.textMuted,
                              letterSpacing: 0.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        template.title,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: completed
                          ? [pt.profit, pt.feltCenter]
                          : [pt.goldDark, pt.goldPrimary],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    completed
                        ? '+${template.xpReward} XP'
                        : '+${template.xpReward} XP',
                    style: textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? pt.profit : pt.goldPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  completed ? 'Completed!' : '$progress / ${template.target}',
                  style: textTheme.labelSmall?.copyWith(
                    color: completed ? pt.profit : pt.textMuted,
                    fontWeight:
                        completed ? FontWeight.w700 : FontWeight.normal,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                Text(
                  completed
                      ? 'Reward claimed'
                      : 'Resets at midnight',
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate(target: completed ? 1 : 0).shimmer(
          duration: 1200.ms,
          color: pt.goldLight.withValues(alpha: 0.5),
        );
  }
}
