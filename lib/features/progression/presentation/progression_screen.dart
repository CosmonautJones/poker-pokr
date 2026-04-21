import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

import 'widgets/achievement_tile.dart';
import 'widgets/streak_calendar.dart';

/// Full-page progression dashboard: level header, XP ring, streak calendar,
/// stat tiles, and the achievements grid. Reached via the home-screen
/// progression card and the Settings → Progression section.
class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final stats = ref.watch(userStatsProvider);

    final unlockedDefs = achievementCatalog
        .where((a) => stats.unlockedAchievementIds.contains(a.id))
        .toList(growable: false);
    final lockedDefs = achievementCatalog
        .where((a) => !stats.unlockedAchievementIds.contains(a.id))
        .toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progression'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _LevelHeader(stats: stats)
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.04, duration: 300.ms),
          const SizedBox(height: 16),
          StreakCalendar(stats: stats)
              .animate()
              .fadeIn(duration: 300.ms, delay: 80.ms)
              .slideY(begin: 0.04, duration: 300.ms, delay: 80.ms),
          const SizedBox(height: 16),
          _StatsGrid(stats: stats)
              .animate()
              .fadeIn(duration: 300.ms, delay: 140.ms)
              .slideY(begin: 0.04, duration: 300.ms, delay: 140.ms),
          const SizedBox(height: 20),
          _AchievementsSectionHeader(
            unlocked: unlockedDefs.length,
            total: achievementCatalog.length,
          ),
          const SizedBox(height: 10),
          _AchievementsGrid(
            unlocked: unlockedDefs,
            locked: lockedDefs,
            unlockedIds: stats.unlockedAchievementIds,
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'More unlocks coming as you play.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Big-hero level card with XP ring and summary line.
class _LevelHeader extends StatelessWidget {
  final UserStats stats;
  const _LevelHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final level = stats.level;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.32),
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
              pt.feltCenter.withValues(alpha: 0.18),
              pt.surfaceDim,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _XpRing(progress: stats.levelProgress, level: level),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Level $level',
                    style: textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.xpIntoLevel} / ${stats.xpNeededForNextLevel} XP '
                    'to next level',
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: pt.goldPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.totalXp} XP lifetime',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
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

/// Circular XP progress ring with the level number in the center.
class _XpRing extends StatelessWidget {
  final double progress;
  final int level;
  const _XpRing({required this.progress, required this.level});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LVL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: pt.textMuted,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                '$level',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Four compact stat tiles: hands, lessons, current streak, best streak.
class _StatsGrid extends StatelessWidget {
  final UserStats stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.style_rounded,
            label: 'Hands',
            value: '${stats.handsPlayed}',
            color: pt.accent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.school_rounded,
            label: 'Lessons',
            value: '${stats.lessonsCompleted}',
            color: pt.seatActiveBorder,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.local_fire_department_rounded,
            label: 'Streak',
            value: '${stats.streakDays}d',
            color: pt.allInGlow,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.emoji_events_rounded,
            label: 'Best',
            value: '${stats.bestStreakDays}d',
            color: pt.goldPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.08),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: pt.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementsSectionHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _AchievementsSectionHeader({
    required this.unlocked,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Icon(Icons.military_tech_rounded, size: 18, color: pt.goldPrimary),
        const SizedBox(width: 6),
        Text(
          'Achievements',
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '$unlocked / $total',
          style: textTheme.labelMedium?.copyWith(
            color: pt.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Achievements grid. Unlocked ones appear first, sorted by catalog order;
/// locked ones follow with a dimmed tile.
class _AchievementsGrid extends StatelessWidget {
  final List<Achievement> unlocked;
  final List<Achievement> locked;
  final Set<String> unlockedIds;

  const _AchievementsGrid({
    required this.unlocked,
    required this.locked,
    required this.unlockedIds,
  });

  @override
  Widget build(BuildContext context) {
    // Keep catalog order so unlocks don't reshuffle wildly as the user
    // earns more. Just show them with their unlock state.
    final ordered = [...unlocked, ...locked];
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 10 * 2) / 3;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final a in ordered)
              SizedBox(
                width: tileWidth,
                child: AchievementTile(
                  achievement: a,
                  unlocked: unlockedIds.contains(a.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
