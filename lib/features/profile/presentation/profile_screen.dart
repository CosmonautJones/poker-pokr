import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Player progression hub: streak/level header, lifetime stats, achievement
/// grid. Reachable from Home (tap progression card) and Settings.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);
    final unlocked = ref.watch(achievementsProvider);
    final unlockedCount = unlocked.length;
    final totalCount = achievementsCatalog.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/home'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _ProfileHeader(stats: stats),
          const SizedBox(height: 16),
          _LifetimeStats(stats: stats),
          const SizedBox(height: 18),
          _NextUpBand(stats: stats, unlocked: unlocked),
          const SizedBox(height: 22),
          _SectionTitle(
            title: 'Achievements',
            trailing: '$unlockedCount / $totalCount',
          ),
          const SizedBox(height: 10),
          _AchievementGrid(stats: stats, unlocked: unlocked),
        ],
      ),
    );
  }
}

/// "Closest to unlock" hero band — surfaces the single locked achievement
/// nearest to its threshold so the player has a near-term goal. Hidden once
/// every achievement is unlocked.
class _NextUpBand extends StatelessWidget {
  final UserStats stats;
  final Set<AchievementId> unlocked;
  const _NextUpBand({required this.stats, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    Achievement? closest;
    double bestProgress = -1;
    for (final a in achievementsCatalog) {
      if (unlocked.contains(a.id)) continue;
      final p = a.progress(stats);
      if (p > bestProgress) {
        bestProgress = p;
        closest = a;
      }
    }
    if (closest == null) return const SizedBox.shrink();

    final current = closest.currentValue(stats);
    final percent = (closest.progress(stats) * 100).round();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.accent.withValues(alpha: 0.10),
            pt.goldPrimary.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: pt.accent.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: pt.accent.withValues(alpha: 0.16),
                  border: Border.all(
                    color: pt.accent.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Icon(closest.icon, size: 18, color: pt.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Up next',
                      style: textTheme.labelSmall?.copyWith(
                        color: pt.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      closest.title,
                      style: textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$current / ${closest.threshold}',
                style: textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: closest.progress(stats),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(pt.accent),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$percent% • ${closest.description}',
            style: textTheme.labelSmall?.copyWith(color: pt.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 280.ms, delay: 80.ms)
        .slideY(begin: 0.04, duration: 280.ms, delay: 80.ms);
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserStats stats;
  const _ProfileHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final progress = stats.levelProgress;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.goldPrimary.withValues(alpha: 0.14),
              pt.feltCenter.withValues(alpha: 0.4),
              pt.surfaceDim,
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [pt.goldPrimary, pt.goldDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pt.goldPrimary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${stats.level}',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${stats.level}',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.totalXp} XP total',
                        style: textTheme.bodySmall?.copyWith(
                          color: pt.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _StreakPill(stats: stats),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${stats.xpIntoLevel} / ${stats.xpNeededForNextLevel} '
              'XP to next level',
              style: textTheme.labelSmall?.copyWith(color: pt.textMuted),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 260.ms)
        .slideY(begin: 0.04, duration: 260.ms);
  }
}

class _StreakPill extends StatelessWidget {
  final UserStats stats;
  const _StreakPill({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final active = Progression.isStreakActive(stats);
    final color = active ? pt.allInGlow : pt.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(
          color: color.withValues(alpha: active ? 0.5 : 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department_rounded, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            '${stats.streakDays}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _LifetimeStats extends StatelessWidget {
  final UserStats stats;
  const _LifetimeStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final winRate = stats.handsPlayed == 0
        ? '—'
        : '${((stats.handsWon / stats.handsPlayed) * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              icon: Icons.style_rounded,
              label: 'Hands',
              value: '${stats.handsPlayed}',
              accent: pt.goldPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.emoji_events_rounded,
              label: 'Won',
              value: '${stats.handsWon}',
              sublabel: 'win rate $winRate',
              accent: pt.profit,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.school_rounded,
              label: 'Lessons',
              value: '${stats.lessonsCompleted}',
              accent: pt.accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              icon: Icons.local_fire_department_rounded,
              label: 'Best',
              value: '${stats.bestStreakDays}',
              sublabel: 'day streak',
              accent: pt.allInGlow,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? sublabel;
  final Color accent;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: pt.surfaceDim.withValues(alpha: 0.5),
        border: Border.all(
          color: accent.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 6),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: pt.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          if (sublabel != null)
            Text(
              sublabel!,
              style: textTheme.labelSmall?.copyWith(
                color: pt.textMuted.withValues(alpha: 0.7),
                fontSize: 9.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const _SectionTitle({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: pt.goldPrimary.withValues(alpha: 0.14),
              border: Border.all(
                color: pt.goldPrimary.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Text(
              trailing!,
              style: textTheme.labelSmall?.copyWith(
                color: pt.goldLight,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
      ],
    );
  }
}

class _AchievementGrid extends StatelessWidget {
  final UserStats stats;
  final Set<AchievementId> unlocked;
  const _AchievementGrid({required this.stats, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    // Group entries by category to render section headers between them.
    final byCategory = <AchievementCategory, List<Achievement>>{};
    for (final a in achievementsCatalog) {
      byCategory.putIfAbsent(a.category, () => []).add(a);
    }

    final children = <Widget>[];
    int globalIndex = 0;
    for (final cat in AchievementCategory.values) {
      final entries = byCategory[cat] ?? const [];
      if (entries.isEmpty) continue;
      children.add(_CategoryHeader(label: cat.label));
      children.add(const SizedBox(height: 8));
      children.add(
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.82,
          children: [
            for (final a in entries)
              _AchievementTile(
                achievement: a,
                stats: stats,
                unlocked: unlocked.contains(a.id),
              )
                  .animate()
                  .fadeIn(
                    duration: 240.ms,
                    delay: (40 * globalIndex++).ms,
                  )
                  .scaleXY(
                    begin: 0.92,
                    end: 1.0,
                    duration: 240.ms,
                    delay: (40 * (globalIndex - 1)).ms,
                    curve: Curves.easeOutBack,
                  ),
          ],
        ),
      );
      children.add(const SizedBox(height: 18));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String label;
  const _CategoryHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label.toUpperCase(),
        style: textTheme.labelSmall?.copyWith(
          color: pt.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 10.5,
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final UserStats stats;
  final bool unlocked;
  const _AchievementTile({
    required this.achievement,
    required this.stats,
    required this.unlocked,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final progress = achievement.progress(stats);
    final iconColor = unlocked ? pt.goldLight : pt.textMuted;
    final borderColor = unlocked
        ? pt.goldPrimary.withValues(alpha: 0.55)
        : pt.borderSubtle.withValues(alpha: 0.35);

    return Tooltip(
      message: achievement.description,
      preferBelow: true,
      waitDuration: const Duration(milliseconds: 250),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: pt.surfaceDim.withValues(alpha: 0.55),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.15),
                    blurRadius: 14,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: unlocked
                    ? pt.goldPrimary.withValues(alpha: 0.16)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: unlocked
                      ? pt.goldPrimary.withValues(alpha: 0.55)
                      : pt.borderSubtle.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(
                unlocked ? achievement.icon : Icons.lock_rounded,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: textTheme.labelSmall?.copyWith(
                color: unlocked
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (!unlocked)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pt.goldPrimary.withValues(alpha: 0.55),
                  ),
                ),
              )
            else
              Text(
                'Unlocked',
                style: textTheme.labelSmall?.copyWith(
                  color: pt.goldLight,
                  fontWeight: FontWeight.w700,
                  fontSize: 9.5,
                  letterSpacing: 0.6,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
