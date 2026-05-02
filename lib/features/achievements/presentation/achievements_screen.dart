import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_icons.dart';

/// Browse all achievements with locked / unlocked state. Locked entries are
/// shown faded with a lock icon to motivate completion.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final unlocked = ref.watch(unlockedAchievementsProvider);

    final groups = <AchievementCategory, List<Achievement>>{};
    for (final a in kAchievements) {
      groups.putIfAbsent(a.category, () => []).add(a);
    }

    final unlockedCount = unlocked.length;
    final total = kAchievements.length;
    final progress = total == 0 ? 0.0 : unlockedCount / total;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _SummaryCard(
            unlocked: unlockedCount,
            total: total,
            progress: progress,
          ),
          const SizedBox(height: 16),
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 6, 4, 8),
              child: Text(
                _categoryLabel(entry.key),
                style: TextStyle(
                  color: pt.goldPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            for (final ach in entry.value)
              _AchievementTile(
                achievement: ach,
                unlocked: unlocked.contains(ach.id),
              ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  String _categoryLabel(AchievementCategory c) {
    switch (c) {
      case AchievementCategory.play:
        return 'Play';
      case AchievementCategory.streak:
        return 'Consistency';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.level:
        return 'Level';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;
  final double progress;

  const _SummaryCard({
    required this.unlocked,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pt.goldPrimary, pt.goldDark],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$unlocked of $total unlocked',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        unlocked == total
                            ? 'Trophy cabinet complete'
                            : 'Keep playing to fill the cabinet',
                        style: textTheme.bodySmall?.copyWith(
                          color: pt.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
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
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool unlocked;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final fg = unlocked ? Colors.white : pt.textMuted;
    final accent = unlocked ? pt.goldPrimary : pt.borderSubtle;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: accent.withValues(alpha: unlocked ? 0.4 : 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked
                    ? LinearGradient(
                        colors: [pt.goldPrimary, pt.goldDark],
                      )
                    : null,
                color: unlocked ? null : pt.surfaceDim,
                border: Border.all(
                  color: accent.withValues(alpha: unlocked ? 0.6 : 0.4),
                  width: 1.2,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                achievementIcon(achievement.iconCodePoint),
                color: unlocked ? Colors.white : pt.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    achievement.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              unlocked
                  ? Icons.check_circle_rounded
                  : Icons.lock_outline_rounded,
              color: unlocked ? pt.profit : pt.textMuted.withValues(alpha: 0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
