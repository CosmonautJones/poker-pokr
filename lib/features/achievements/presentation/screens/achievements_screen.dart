import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/widgets/achievement_badge.dart';

/// Grid view of every achievement, grouped by category, with a header
/// summarizing unlock progress. Tapping a badge opens a detail sheet.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final stats = ref.watch(userStatsProvider);

    final all = AchievementsCatalog.all;
    final unlockedCount =
        all.where((a) => stats.unlockedAchievementIds.contains(a.id)).length;
    final progress = all.isEmpty ? 0.0 : unlockedCount / all.length;

    final byCategory = <AchievementCategory, List<Achievement>>{};
    for (final a in all) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _ProgressHeader(
            unlocked: unlockedCount,
            total: all.length,
            progress: progress,
          )
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.04, duration: 250.ms),
          const SizedBox(height: 18),
          for (final entry in byCategory.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
              child: Text(
                entry.key.displayName.toUpperCase(),
                style: textTheme.labelSmall?.copyWith(
                  color: pt.goldPrimary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
              children: [
                for (final a in entry.value)
                  _BadgeTile(
                    achievement: a,
                    unlocked: stats.unlockedAchievementIds.contains(a.id),
                    stats: stats,
                  ),
              ],
            ),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;
  final UserStats stats;

  const _BadgeTile({
    required this.achievement,
    required this.unlocked,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: AchievementBadge(
          achievement: achievement,
          unlocked: unlocked,
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: unlocked
                    ? pt.goldPrimary.withValues(alpha: 0.4)
                    : pt.borderSubtle.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AchievementBadge(
                  achievement: achievement,
                  unlocked: unlocked,
                ),
                const SizedBox(height: 14),
                Text(
                  achievement.title,
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  achievement.description,
                  style: textTheme.bodyMedium?.copyWith(
                    color: pt.textMuted,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: unlocked
                        ? pt.goldPrimary.withValues(alpha: 0.18)
                        : pt.surfaceDim,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: unlocked
                          ? pt.goldPrimary.withValues(alpha: 0.5)
                          : pt.borderSubtle.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    unlocked ? 'UNLOCKED' : 'LOCKED',
                    style: textTheme.labelSmall?.copyWith(
                      color: unlocked ? pt.goldPrimary : pt.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  final double progress;

  const _ProgressHeader({
    required this.unlocked,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.goldPrimary.withValues(alpha: 0.15),
            pt.goldDark.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: pt.goldPrimary),
              const SizedBox(width: 8),
              Text(
                'Trophy Case',
                style: textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '$unlocked / $total',
                style: textTheme.titleSmall?.copyWith(
                  color: pt.goldPrimary,
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
