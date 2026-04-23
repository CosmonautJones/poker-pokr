import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final progress = ref.watch(achievementsProvider);
    final all = AchievementsCatalog.all;
    final unlockedCount = progress.unlockedCount;
    final totalCount = all.length;
    final pct = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    final grouped = <AchievementCategory, List<Achievement>>{};
    for (final a in all) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _HeaderProgress(
            unlocked: unlockedCount,
            total: totalCount,
            progress: pct,
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.04, duration: 300.ms),
          const SizedBox(height: 18),
          for (final entry in grouped.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
              child: Text(
                _categoryLabel(entry.key),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: pt.goldPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
              ),
            ),
            for (final a in entry.value)
              _AchievementTile(
                achievement: a,
                unlockedAt: progress.unlockedAt[a.id],
              ).animate().fadeIn(duration: 260.ms),
          ],
        ],
      ),
    );
  }

  static String _categoryLabel(AchievementCategory c) {
    switch (c) {
      case AchievementCategory.firstSteps:
        return 'First Steps';
      case AchievementCategory.streak:
        return 'Streaks';
      case AchievementCategory.grind:
        return 'The Grind';
      case AchievementCategory.mastery:
        return 'Mastery';
      case AchievementCategory.profit:
        return 'Profit';
      case AchievementCategory.skill:
        return 'Skill';
    }
  }
}

class _HeaderProgress extends StatelessWidget {
  final int unlocked;
  final int total;
  final double progress;

  const _HeaderProgress({
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
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              pt.goldPrimary.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    color: pt.goldPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '$unlocked / $total unlocked',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
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
  final DateTime? unlockedAt;

  const _AchievementTile({
    required this.achievement,
    required this.unlockedAt,
  });

  Color _rarityColor(PokerTheme pt) {
    switch (achievement.rarity) {
      case AchievementRarity.common:
        return pt.textMuted;
      case AchievementRarity.rare:
        return pt.turnIndicatorGlow;
      case AchievementRarity.epic:
        return pt.straddlePrimary;
      case AchievementRarity.legendary:
        return pt.goldPrimary;
    }
  }

  String _rarityLabel() {
    switch (achievement.rarity) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = unlockedAt != null;
    final rarity = _rarityColor(pt);
    final iconColor = unlocked ? pt.goldPrimary : pt.textMuted;

    return Card(
      elevation: unlocked ? 2 : 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unlocked
              ? pt.goldPrimary.withValues(alpha: 0.40)
              : pt.borderSubtle.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      iconColor.withValues(alpha: unlocked ? 0.25 : 0.10),
                      Colors.transparent,
                    ],
                  ),
                  border: Border.all(
                    color: iconColor.withValues(alpha: unlocked ? 0.8 : 0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  IconData(achievement.iconCodePoint,
                      fontFamily: 'MaterialIcons'),
                  color: iconColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: textTheme.titleSmall?.copyWith(
                            color: unlocked
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.7),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: rarity.withValues(alpha: 0.7),
                            width: 1,
                          ),
                          color: rarity.withValues(alpha: 0.08),
                        ),
                        child: Text(
                          _rarityLabel(),
                          style: textTheme.labelSmall?.copyWith(
                            color: rarity,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement.description,
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted,
                      height: 1.3,
                    ),
                  ),
                  if (unlocked) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Unlocked ${_formatDate(unlockedAt!)}',
                      style: textTheme.labelSmall?.copyWith(
                        color: pt.goldPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final local = dt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
