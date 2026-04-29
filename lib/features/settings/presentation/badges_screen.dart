import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievement_catalog.dart';
import 'package:poker_trainer/core/progression/achievement_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Grid of every achievement in the catalog.
///
/// Locked badges show as desaturated tiles with the description as a hint;
/// unlocked badges glow gold and show an "Unlocked!" caption. Incremental
/// achievements (>1 target) display a progress bar with current / target.
class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final unlocked = ref.watch(
      achievementsProvider.select((s) => s.unlockedIds),
    );
    final pt = context.poker;
    final all = AchievementCatalog.all;
    final unlockedCount = all.where((a) => unlocked.contains(a.id)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: pt.goldPrimary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '$unlockedCount of ${all.length} unlocked',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: pt.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.86,
                    ),
                    itemCount: all.length,
                    itemBuilder: (context, index) {
                      final a = all[index];
                      final isUnlocked = unlocked.contains(a.id);
                      return _BadgeTile(
                        achievement: a,
                        stats: stats,
                        isUnlocked: isUnlocked,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;
  final bool isUnlocked;

  const _BadgeTile({
    required this.achievement,
    required this.stats,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final progress = achievement.progressFor(stats);
    final fraction = achievement.progressFraction(stats).clamp(0.0, 1.0);
    final iconColor = isUnlocked ? pt.goldPrimary : pt.textMuted;
    final iconBgColors = isUnlocked
        ? [pt.goldLight.withValues(alpha: 0.85), pt.goldPrimary, pt.goldDark]
        : [
            pt.surfaceDim.withValues(alpha: 0.6),
            pt.borderSubtle.withValues(alpha: 0.6),
            pt.surfaceDim.withValues(alpha: 0.6),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: isUnlocked ? 0.55 : 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? pt.goldPrimary.withValues(alpha: 0.55)
              : pt.borderSubtle.withValues(alpha: 0.6),
          width: isUnlocked ? 1.2 : 0.8,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : const [],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: iconBgColors),
                ),
                child: Icon(
                  achievement.iconData,
                  size: 28,
                  color: isUnlocked
                      ? Colors.black.withValues(alpha: 0.85)
                      : iconColor,
                ),
              ),
              if (isUnlocked)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: pt.goldPrimary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.black,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Colors.black,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isUnlocked ? Colors.white : pt.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Center(
              child: Text(
                isUnlocked ? 'Unlocked!' : achievement.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnlocked
                      ? pt.goldLight
                      : pt.textMuted.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontStyle: isUnlocked ? FontStyle.normal : FontStyle.italic,
                  fontWeight:
                      isUnlocked ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (achievement.targetValue > 1) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: pt.borderSubtle.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isUnlocked ? pt.goldPrimary : pt.goldDark,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$progress / ${achievement.targetValue}',
              style: TextStyle(
                color: pt.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
