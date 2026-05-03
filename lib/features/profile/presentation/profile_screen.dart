import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

import 'achievement_icons.dart';

/// Stats + achievements + streak summary destination. Reachable from the
/// home screen progression card; provides a "where am I" snapshot of the
/// player's progress and an achievement grid to chase.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final stats = ref.watch(userStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
        backgroundColor: pt.surfaceDim,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _LevelCard(stats: stats)
                .animate()
                .fadeIn(duration: 280.ms)
                .slideY(begin: 0.04, duration: 280.ms),
            const SizedBox(height: 12),
            _StatRow(stats: stats)
                .animate()
                .fadeIn(duration: 280.ms, delay: 80.ms)
                .slideY(begin: 0.04, duration: 280.ms, delay: 80.ms),
            const SizedBox(height: 22),
            _SectionHeader(
              title: 'Achievements',
              trailing: _ProgressLabel(stats: stats),
            )
                .animate()
                .fadeIn(duration: 280.ms, delay: 140.ms),
            const SizedBox(height: 10),
            _AchievementGrid(stats: stats)
                .animate()
                .fadeIn(duration: 320.ms, delay: 180.ms),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final UserStats stats;
  const _LevelCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
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
              pt.feltCenter.withValues(alpha: 0.5),
              pt.goldPrimary.withValues(alpha: 0.10),
              pt.surfaceDim,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [pt.goldDark, pt.goldPrimary],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'LEVEL ${stats.level}',
                    style: textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${stats.totalXp} XP',
                  style: textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: stats.levelProgress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${stats.xpIntoLevel} / ${stats.xpNeededForNextLevel} XP '
              'to level ${stats.level + 1}',
              style: textTheme.bodySmall?.copyWith(
                color: pt.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final UserStats stats;
  const _StatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            iconData: Icons.local_fire_department_rounded,
            iconColor: pt.allInGlow,
            label: 'Streak',
            value: '${stats.streakDays}',
            sub: stats.bestStreakDays > stats.streakDays
                ? 'Best ${stats.bestStreakDays}'
                : 'Best ${stats.bestStreakDays}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            iconData: Icons.casino_rounded,
            iconColor: pt.accent,
            label: 'Hands',
            value: '${stats.handsPlayed}',
            sub: '${stats.lifetimeWins} won',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            iconData: Icons.school_rounded,
            iconColor: pt.seatActiveBorder,
            label: 'Lessons',
            value: '${stats.lessonsCompleted}',
            sub: '${stats.dailyChallengesCompleted} dailies',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData iconData;
  final Color iconColor;
  final String label;
  final String value;
  final String sub;

  const _StatTile({
    required this.iconData,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(iconData, color: iconColor, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            Text(
              sub,
              style: textTheme.labelSmall?.copyWith(
                color: pt.textMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _ProgressLabel extends StatelessWidget {
  final UserStats stats;
  const _ProgressLabel({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final earned = stats.unlockedAchievements
        .where((id) => findAchievementById(id) != null)
        .length;
    final total = achievementCatalog.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: pt.goldPrimary.withValues(alpha: 0.12),
        border: Border.all(color: pt.goldPrimary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$earned / $total',
        style: textTheme.labelSmall?.copyWith(
          color: pt.goldPrimary,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final UserStats stats;
  const _AchievementGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final unlockedSet = stats.unlockedAchievements.toSet();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: achievementCatalog.length,
      itemBuilder: (context, index) {
        final a = achievementCatalog[index];
        final earned = unlockedSet.contains(a.id);
        return _AchievementTile(achievement: a, earned: earned);
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool earned;

  const _AchievementTile({required this.achievement, required this.earned});

  Color _tierColor(PokerTheme pt) {
    return switch (achievement.tier) {
      AchievementTier.bronze => const Color(0xFFB87333),
      AchievementTier.silver => const Color(0xFFC0C0C0),
      AchievementTier.gold => pt.goldPrimary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final tier = _tierColor(pt);

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: pt.surfaceDim,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: earned
                ? tier.withValues(alpha: 0.7)
                : pt.borderSubtle.withValues(alpha: 0.3),
            width: earned ? 1.4 : 1.0,
          ),
          boxShadow: earned
              ? [
                  BoxShadow(
                    color: tier.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: earned
                    ? LinearGradient(
                        colors: [tier, tier.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: earned ? null : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: earned
                      ? Colors.white.withValues(alpha: 0.4)
                      : pt.borderSubtle.withValues(alpha: 0.4),
                ),
              ),
              child: Icon(
                earned
                    ? achievementIcon(achievement.iconKey)
                    : Icons.lock_rounded,
                color: earned
                    ? Colors.white
                    : pt.textMuted,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: earned
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final pt = context.poker;
    final tier = _tierColor(pt);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pt.surfaceDim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: earned
                          ? LinearGradient(
                              colors: [tier, tier.withValues(alpha: 0.6)],
                            )
                          : null,
                      color: earned
                          ? null
                          : Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: tier.withValues(alpha: earned ? 0.7 : 0.3),
                      ),
                    ),
                    child: Icon(
                      earned
                          ? achievementIcon(achievement.iconKey)
                          : Icons.lock_rounded,
                      color: earned ? Colors.white : pt.textMuted,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          earned ? 'Unlocked' : 'Locked',
                          style: textTheme.labelMedium?.copyWith(
                            color: earned ? tier : pt.textMuted,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
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
            ],
          ),
        );
      },
    );
  }
}
