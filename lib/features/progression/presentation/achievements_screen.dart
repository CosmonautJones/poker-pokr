import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievement_visuals.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Browsable grid of every achievement. Shows unlocked cards first (most
/// recent at the top), then locked cards sorted by how close the player is
/// to clearing them so progress feels "almost there" instead of distant.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    final sorted = _sortedForDisplay(stats);
    final unlockedCount = stats.unlockedAchievements.length;
    final totalCount = AchievementCatalog.totalCount;
    final completion =
        totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 28,
                        color: pt.goldPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Trophy Case',
                              style: textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$unlockedCount of $totalCount unlocked',
                              style: textTheme.bodySmall?.copyWith(
                                color: pt.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: completion,
                      minHeight: 6,
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(pt.goldPrimary),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.95,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _AchievementTile(
                  achievement: sorted[index],
                  stats: stats,
                ),
                childCount: sorted.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  static List<Achievement> _sortedForDisplay(UserStats stats) {
    final all = AchievementCatalog.all;
    final unlocked = <Achievement>[];
    final locked = <Achievement>[];
    for (final a in all) {
      if (stats.unlockedAchievements.containsKey(a.id)) {
        unlocked.add(a);
      } else {
        locked.add(a);
      }
    }
    unlocked.sort((a, b) {
      final ta = stats.unlockedAchievements[a.id]!;
      final tb = stats.unlockedAchievements[b.id]!;
      return tb.compareTo(ta); // newest first
    });
    locked.sort((a, b) {
      // Closest to completion first.
      final pa = a.progressFraction(stats);
      final pb = b.progressFraction(stats);
      final cmp = pb.compareTo(pa);
      if (cmp != 0) return cmp;
      return a.target.compareTo(b.target);
    });
    return [...unlocked, ...locked];
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;

  const _AchievementTile({
    required this.achievement,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = stats.unlockedAchievements.containsKey(achievement.id);
    final tierColor = achievement.tier.displayColor(pt);
    final accentColor = unlocked ? tierColor : pt.textMuted;
    final progress = achievement.progressFraction(stats);
    final progressText =
        '${achievement.progress(stats).clamp(0, achievement.target)}'
        ' / ${achievement.target}';

    return Opacity(
      opacity: unlocked ? 1.0 : 0.82,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: unlocked
                ? [
                    pt.surfaceOverlay,
                    tierColor.withValues(alpha: 0.14),
                    pt.surfaceDim,
                  ]
                : [
                    pt.surfaceOverlay,
                    pt.surfaceDim,
                  ],
          ),
          border: Border.all(
            color: unlocked
                ? tierColor.withValues(alpha: 0.55)
                : pt.borderSubtle.withValues(alpha: 0.35),
            width: 1,
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: tierColor.withValues(alpha: 0.20),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentColor.withValues(alpha: unlocked ? 0.35 : 0.15),
                        Colors.transparent,
                      ],
                    ),
                    border: Border.all(
                      color: accentColor.withValues(alpha: unlocked ? 0.8 : 0.4),
                      width: 1.25,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    unlocked ? achievement.icon : Icons.lock_rounded,
                    size: 20,
                    color: accentColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    achievement.tier.label.toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      fontSize: 9,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              style: textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Text(
                achievement.description,
                style: textTheme.bodySmall?.copyWith(
                  color: pt.textMuted,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            if (unlocked)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 14, color: tierColor),
                  const SizedBox(width: 4),
                  Text(
                    'Unlocked',
                    style: textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              )
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor:
                      Colors.white.withValues(alpha: 0.06),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(accentColor),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                progressText,
                style: textTheme.labelSmall?.copyWith(
                  color: pt.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
