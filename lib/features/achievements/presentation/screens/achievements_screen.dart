import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:poker_trainer/core/progression/achievements/achievement.dart';
import 'package:poker_trainer/core/progression/achievements/achievement_progress.dart';
import 'package:poker_trainer/core/progression/achievements/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/widgets/daily_challenge_card.dart';

/// Wall of achievements + daily challenge. Reachable from Home and Settings.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProvider);
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = state.unlockedCount;
    final total = achievementsCatalog.length;

    final grouped = _groupByCategory(achievementsCatalog);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(36),
          child: Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Icon(Icons.emoji_events_rounded,
                    size: 16, color: pt.goldPrimary),
                const SizedBox(width: 6),
                Text(
                  '$unlocked of $total unlocked',
                  style: textTheme.bodySmall?.copyWith(
                    color: pt.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                if (total > 0)
                  SizedBox(
                    width: 120,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: unlocked / total,
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          pt.goldPrimary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
        children: [
          const DailyChallengeCard(),
          const SizedBox(height: 16),
          for (final entry in grouped.entries) ...[
            _CategoryHeader(label: _categoryLabel(entry.key)),
            const SizedBox(height: 8),
            _AchievementGrid(items: entry.value, state: state),
            const SizedBox(height: 18),
          ],
        ],
      ),
    );
  }

  static Map<AchievementCategory, List<Achievement>> _groupByCategory(
    List<Achievement> all,
  ) {
    final out = <AchievementCategory, List<Achievement>>{};
    for (final a in all) {
      out.putIfAbsent(a.category, () => []).add(a);
    }
    return out;
  }

  static String _categoryLabel(AchievementCategory c) => switch (c) {
        AchievementCategory.volume => 'Volume',
        AchievementCategory.mastery => 'Hand Mastery',
        AchievementCategory.drills => 'Drills',
        AchievementCategory.habit => 'Habit',
        AchievementCategory.variety => 'Variety',
      };
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: pt.goldPrimary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final List<Achievement> items;
  final AchievementsState state;

  const _AchievementGrid({required this.items, required this.state});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final ach = items[index];
        final progress = state.progressFor(ach.id);
        return _AchievementTile(
          achievement: ach,
          progress: progress,
        ).animate().fadeIn(
              duration: 280.ms,
              delay: (index * 30).ms,
            );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress progress;

  const _AchievementTile({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = progress.isUnlocked;
    final tierColor = _tierColor(achievement.tier, pt);
    final fraction = (progress.value / achievement.threshold)
        .clamp(0.0, 1.0)
        .toDouble();

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _showDetails(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: unlocked
                ? [
                    tierColor.withValues(alpha: 0.18),
                    pt.surfaceDim,
                  ]
                : [
                    pt.surfaceDim,
                    pt.surfaceDim,
                  ],
          ),
          border: Border.all(
            color: unlocked
                ? tierColor.withValues(alpha: 0.6)
                : pt.borderSubtle.withValues(alpha: 0.4),
            width: unlocked ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: unlocked
                        ? RadialGradient(colors: [
                            tierColor.withValues(alpha: 0.55),
                            tierColor.withValues(alpha: 0.10),
                          ])
                        : null,
                    color: unlocked
                        ? null
                        : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: unlocked
                          ? tierColor.withValues(alpha: 0.7)
                          : pt.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    unlocked
                        ? achievement.icon
                        : Icons.lock_rounded,
                    size: 16,
                    color: unlocked
                        ? tierColor
                        : pt.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    achievement.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: unlocked
                          ? Colors.white
                          : pt.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              achievement.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: pt.textMuted,
                height: 1.25,
              ),
            ),
            const Spacer(),
            if (unlocked)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      size: 12, color: tierColor),
                  const SizedBox(width: 4),
                  Text(
                    progress.unlockedAt != null
                        ? 'Unlocked ${DateFormat.yMMMd().format(progress.unlockedAt!)}'
                        : 'Unlocked',
                    style: textTheme.labelSmall?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          tierColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${progress.value}/${achievement.threshold}',
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AchievementDetailsSheet(
        achievement: achievement,
        progress: progress,
      ),
    );
  }

  static Color _tierColor(AchievementTier tier, PokerTheme pt) {
    return switch (tier) {
      AchievementTier.bronze => const Color(0xFFCD7F32),
      AchievementTier.silver => const Color(0xFFB0B7BD),
      AchievementTier.gold => pt.goldPrimary,
      AchievementTier.platinum => const Color(0xFF7DD3FC),
    };
  }
}

class _AchievementDetailsSheet extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress progress;

  const _AchievementDetailsSheet({
    required this.achievement,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = progress.isUnlocked;
    final tierColor =
        _AchievementTile._tierColor(achievement.tier, pt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: pt.borderSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    tierColor.withValues(alpha: 0.55),
                    tierColor.withValues(alpha: 0.05),
                  ]),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.7),
                  ),
                ),
                child: Icon(
                  unlocked ? achievement.icon : Icons.lock_rounded,
                  color: tierColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      achievement.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _tierLabel(achievement.tier),
                      style: textTheme.labelSmall?.copyWith(
                        color: tierColor,
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w700,
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
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.bolt_rounded,
                  color: pt.goldPrimary, size: 18),
              const SizedBox(width: 6),
              Text(
                '+${achievement.xpReward} XP reward',
                style: textTheme.bodySmall?.copyWith(
                  color: pt.goldPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (unlocked)
                Text(
                  progress.unlockedAt != null
                      ? 'Earned ${DateFormat.yMMMMd().format(progress.unlockedAt!)}'
                      : 'Earned',
                  style: textTheme.bodySmall?.copyWith(
                    color: pt.textMuted,
                  ),
                )
              else
                Text(
                  '${progress.value} / ${achievement.threshold}',
                  style: textTheme.bodySmall?.copyWith(
                    color: pt.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _tierLabel(AchievementTier t) => switch (t) {
        AchievementTier.bronze => 'BRONZE',
        AchievementTier.silver => 'SILVER',
        AchievementTier.gold => 'GOLD',
        AchievementTier.platinum => 'PLATINUM',
      };
}
