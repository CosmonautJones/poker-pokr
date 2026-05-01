import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Full-screen gallery of every achievement, locked + unlocked.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocks = ref.watch(unlockedAchievementsProvider);
    final all = AchievementsCatalog.all;
    final unlockedCount = unlocks.count;
    final total = all.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '$unlockedCount / $total',
                style: textTheme.titleMedium?.copyWith(
                  color: pt.goldPrimary,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 3 columns on tablet-ish widths, 2 on phones.
            final crossAxis = constraints.maxWidth >= 600 ? 3 : 2;
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: _SummaryCard(
                      unlocked: unlockedCount,
                      total: total,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final a = all[i];
                        return _AchievementTile(
                          achievement: a,
                          unlockedAt: unlocks.unlockedAt[a.id],
                        )
                            .animate()
                            .fadeIn(
                              duration: 260.ms,
                              delay: (40 * i).ms,
                            )
                            .slideY(
                              begin: 0.1,
                              end: 0,
                              duration: 260.ms,
                              delay: (40 * i).ms,
                              curve: Curves.easeOutCubic,
                            );
                      },
                      childCount: all.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;

  const _SummaryCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: pt.borderSubtle),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.goldPrimary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: pt.goldPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                '$unlocked of $total unlocked',
                style: textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.achievement,
    required this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = unlockedAt != null;
    final tier = tierColor(pt, achievement.tier);

    final tile = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked
              ? tier.withValues(alpha: 0.55)
              : pt.borderSubtle,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: unlocked
              ? [
                  tier.withValues(alpha: 0.18),
                  pt.surfaceDim,
                ]
              : [
                  pt.surfaceDim,
                  pt.surfaceDim,
                ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tier.withValues(alpha: unlocked ? 0.45 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: tier.withValues(alpha: unlocked ? 0.85 : 0.35),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  achievement.icon,
                  size: 24,
                  color: unlocked ? tier : pt.textMuted,
                ),
              ),
              if (!unlocked)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: pt.surfaceDim,
                      shape: BoxShape.circle,
                      border: Border.all(color: pt.borderSubtle),
                    ),
                    child: Icon(
                      Icons.lock_rounded,
                      size: 12,
                      color: pt.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: unlocked ? Colors.white : pt.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            unlocked
                ? 'Unlocked ${_formatDate(unlockedAt!)}'
                : achievement.hint,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: unlocked ? pt.goldLight : pt.textMuted,
              fontFeatures: unlocked
                  ? const [FontFeature.tabularFigures()]
                  : null,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: unlocked
          ? '${achievement.title}, unlocked, ${achievement.tier.name} tier'
          : '${achievement.title}, locked. ${achievement.hint}',
      // Slight dim on locked tiles, but kept above 0.78 so the muted text
      // still meets WCAG-AA contrast against the dark surface.
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.78,
        child: tile,
      ),
    );
  }

  static String _formatDate(DateTime ts) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[ts.month - 1]} ${ts.day}';
  }
}
