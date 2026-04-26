import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement_state.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';

String _tierLabel(AchievementTier tier) {
  switch (tier) {
    case AchievementTier.bronze:
      return 'Bronze';
    case AchievementTier.silver:
      return 'Silver';
    case AchievementTier.gold:
      return 'Gold';
  }
}

class AchievementGrid extends ConsumerWidget {
  const AchievementGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final achievements = ref.watch(achievementStateProvider);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: kAchievements.length,
      itemBuilder: (context, index) {
        final a = kAchievements[index];
        final tile = _AchievementTile(
          achievement: a,
          stats: stats,
          state: achievements,
        );
        return tile
            .animate()
            .fadeIn(
              duration: 280.ms,
              delay: Duration(milliseconds: 50 * index),
            )
            .slideY(
              begin: 0.06,
              duration: 280.ms,
              delay: Duration(milliseconds: 50 * index),
              curve: Curves.easeOut,
            );
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;
  final AchievementState state;

  const _AchievementTile({
    required this.achievement,
    required this.stats,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = state.isUnlocked(achievement.id);
    final tierColor = tierColorOf(context, achievement.tier);
    final progressFraction = achievement.progressFraction(stats);
    final progressValue = achievement.progressValue(stats);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: unlocked ? 3 : 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unlocked
              ? tierColor.withValues(alpha: 0.55)
              : pt.borderSubtle.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showDetail(context),
        child: Container(
          decoration: BoxDecoration(
            gradient: unlocked
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      tierColor.withValues(alpha: 0.16),
                      Colors.transparent,
                    ],
                  )
                : null,
          ),
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
          child: Column(
            children: [
              _Badge(
                tierColor: tierColor,
                icon: achievement.icon,
                unlocked: unlocked,
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: unlocked
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (unlocked)
                Text(
                  _formatUnlockDate(state.unlockDate(achievement.id)),
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 4,
                        backgroundColor:
                            Colors.white.withValues(alpha: 0.06),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(tierColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$progressValue / ${achievement.target}',
                      textAlign: TextAlign.center,
                      style: textTheme.labelSmall?.copyWith(
                        color: pt.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatUnlockDate(DateTime? when) {
    if (when == null) return 'Unlocked';
    return 'Earned ${DateFormatter.formatDate(when)}';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.poker.surfaceDim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return _AchievementDetailSheet(
          achievement: achievement,
          stats: stats,
          state: state,
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  final Color tierColor;
  final IconData icon;
  final bool unlocked;

  const _Badge({
    required this.tierColor,
    required this.icon,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: unlocked
                  ? RadialGradient(
                      colors: [
                        tierColor.withValues(alpha: 0.55),
                        tierColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: unlocked ? null : Colors.white.withValues(alpha: 0.04),
              border: Border.all(
                color: unlocked
                    ? tierColor.withValues(alpha: 0.85)
                    : pt.borderSubtle.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: tierColor.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          Icon(
            icon,
            size: 26,
            color: unlocked
                ? Colors.white
                : pt.textMuted.withValues(alpha: 0.6),
          ),
          if (!unlocked)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: pt.surfaceDim,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: pt.borderSubtle.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lock_rounded,
                  size: 10,
                  color: pt.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AchievementDetailSheet extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;
  final AchievementState state;

  const _AchievementDetailSheet({
    required this.achievement,
    required this.stats,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = state.isUnlocked(achievement.id);
    final tierColor = tierColorOf(context, achievement.tier);
    final progressValue = achievement.progressValue(stats);
    final unlockDate = state.unlockDate(achievement.id);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Badge(
                  tierColor: tierColor,
                  icon: achievement.icon,
                  unlocked: unlocked,
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
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_tierLabel(achievement.tier)} tier',
                        style: textTheme.labelSmall?.copyWith(
                          color: tierColor,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: achievement.progressFraction(stats),
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '$progressValue / ${achievement.target}',
                  style: textTheme.labelMedium?.copyWith(
                    color: pt.textMuted,
                  ),
                ),
                const Spacer(),
                if (unlocked && unlockDate != null)
                  Text(
                    'Earned ${DateFormatter.formatDate(unlockDate)}',
                    style: textTheme.labelMedium?.copyWith(
                      color: tierColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Text(
                    'Locked',
                    style: textTheme.labelMedium?.copyWith(
                      color: pt.textMuted,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
