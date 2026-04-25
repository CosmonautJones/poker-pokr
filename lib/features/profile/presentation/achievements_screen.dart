import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievement_icons.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// "Trophy Cabinet" — every achievement, locked or unlocked, with a progress
/// bar and unlock animation. Reachable from Settings.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final stats = ref.watch(userStatsProvider);
    final evaluator = ref.watch(achievementEvaluatorProvider);
    final unlocked = stats.unlockedAchievementIds;
    final total = achievementsCatalog.length;
    final unlockedCount =
        achievementsCatalog.where((a) => unlocked.contains(a.id.key)).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trophy Cabinet'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/settings'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SummaryHeader(
            unlocked: unlockedCount,
            total: total,
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: achievementsCatalog.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, i) {
              final achievement = achievementsCatalog[i];
              final isUnlocked = unlocked.contains(achievement.id.key);
              final progress = evaluator.progress(achievement.id, stats);
              return _AchievementTile(
                achievement: achievement,
                progress: progress,
                isUnlocked: isUnlocked,
              )
                  .animate()
                  .fadeIn(duration: 280.ms, delay: (40 * i).ms)
                  .slideY(begin: 0.06, duration: 280.ms, delay: (40 * i).ms);
            },
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              unlockedCount == total
                  ? 'All trophies earned — you’re a TableSense legend.'
                  : 'Keep playing to unlock more.',
              style: TextStyle(color: pt.textMuted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _SummaryHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final pct = total == 0 ? 0.0 : unlocked / total;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.3),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.goldPrimary.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [pt.goldPrimary, pt.goldDark],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$unlocked / $total earned',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(pt.goldPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress progress;
  final bool isUnlocked;

  const _AchievementTile({
    required this.achievement,
    required this.progress,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final iconColor = isUnlocked ? pt.goldPrimary : pt.textMuted;
    final borderColor = isUnlocked
        ? pt.goldPrimary.withValues(alpha: 0.55)
        : pt.borderSubtle.withValues(alpha: 0.4);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isUnlocked ? 4 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: isUnlocked ? 1.2 : 1),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    pt.goldPrimary.withValues(alpha: 0.12),
                    Colors.transparent,
                  ]
                : [
                    pt.surfaceDim.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? pt.goldPrimary.withValues(alpha: 0.18)
                        : pt.surfaceDim.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isUnlocked
                          ? pt.goldPrimary.withValues(alpha: 0.5)
                          : pt.borderSubtle.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    isUnlocked
                        ? achievementIcon(achievement.iconCodePoint)
                        : Icons.lock_rounded,
                    size: 22,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                if (isUnlocked)
                  Icon(Icons.check_circle_rounded,
                      size: 18, color: pt.profit)
                else
                  Text(
                    '${progress.current}/${progress.target}',
                    style: TextStyle(
                      color: pt.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              achievement.title,
              style: TextStyle(
                color: isUnlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                achievement.description,
                style: TextStyle(color: pt.textMuted, fontSize: 11.5, height: 1.3),
              ),
            ),
            if (!isUnlocked) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.fraction,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(pt.goldPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
