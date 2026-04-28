import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/daily_challenges.dart';
import 'package:poker_trainer/core/progression/daily_challenges_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Dedicated progression hub: level/XP header, daily challenges, achievements.
class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final stats = ref.watch(userStatsProvider);
    final achievements = ref.watch(achievementsProvider);
    final challengesAsync = ref.watch(dailyChallengesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progression'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: RefreshIndicator(
        color: pt.goldPrimary,
        onRefresh: () async {
          ref.read(hapticServiceProvider).light();
          await ref
              .read(achievementsProvider.notifier)
              .evaluate(stats);
          await ref
              .read(dailyChallengesProvider.notifier)
              .refresh();
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _LevelHeader(stats: stats)
                .animate()
                .fadeIn(duration: 250.ms)
                .slideY(begin: 0.04, duration: 250.ms),
            const SizedBox(height: 20),
            const _SectionTitle(label: 'Daily Challenges'),
            const SizedBox(height: 8),
            challengesAsync.when(
              data: (list) => Column(
                children: [
                  for (final c in list) ...[
                    _ChallengeCard(challenge: c),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Could not load challenges: $e',
                style: TextStyle(color: pt.loss),
              ),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(label: 'Achievements'),
            const SizedBox(height: 8),
            _AchievementsGrid(items: achievements),
          ],
        ),
      ),
    );
  }
}

/// Level + XP bar — mirrors the gold gradient used by the home progression
/// card so the destination feels like a continuation of the source.
class _LevelHeader extends StatelessWidget {
  final UserStats stats;
  const _LevelHeader({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final level = stats.level;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.feltCenter.withValues(alpha: 0.45),
            pt.goldPrimary.withValues(alpha: 0.10),
            pt.surfaceDim,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.32),
        ),
      ),
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
                    colors: [pt.goldLight, pt.goldDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: pt.goldPrimary.withValues(alpha: 0.45),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  '$level',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level $level',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.totalXp} XP total • ${stats.handsPlayed} hands • '
                      '${stats.lessonsCompleted} lessons',
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
              value: stats.levelProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${stats.xpIntoLevel} / ${stats.xpNeededForNextLevel} XP',
                style: textTheme.labelSmall?.copyWith(color: pt.textMuted),
              ),
              const Spacer(),
              Text(
                'Next: Lvl ${level + 1}',
                style: textTheme.labelSmall?.copyWith(color: pt.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        label,
        style: textTheme.titleSmall?.copyWith(
          color: pt.goldLight,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  const _ChallengeCard({required this.challenge});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final def = DailyChallenges.byId(challenge.definitionId);
    if (def == null) return const SizedBox.shrink();

    final ratio = def.target == 0
        ? 0.0
        : (challenge.progress / def.target).clamp(0.0, 1.0);
    final completed = challenge.completed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: pt.surfaceDim.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: completed
              ? pt.goldPrimary.withValues(alpha: 0.55)
              : pt.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? pt.goldPrimary.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(
              completed ? Icons.check_circle_rounded : def.icon,
              color: completed ? pt.goldPrimary : pt.goldLight,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.title,
                        style: textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: pt.goldPrimary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: pt.goldPrimary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Text(
                        '+${def.xpReward} XP',
                        style: textTheme.labelSmall?.copyWith(
                          color: pt.goldLight,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${challenge.progress} / ${def.target}',
                  style: textTheme.bodySmall?.copyWith(color: pt.textMuted),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 5,
                    backgroundColor: Colors.white.withValues(alpha: 0.06),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(pt.goldPrimary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementsGrid extends StatelessWidget {
  final List<Achievement> items;
  const _AchievementsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final a = items[index];
        final def = Achievements.byId(a.definitionId);
        if (def == null) return const SizedBox.shrink();
        return _AchievementTile(definition: def, achievement: a);
      },
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDefinition definition;
  final Achievement achievement;

  const _AchievementTile({required this.definition, required this.achievement});

  String _formatUnlockDate(DateTime ts) {
    final m = ts.month.toString().padLeft(2, '0');
    final d = ts.day.toString().padLeft(2, '0');
    return '${ts.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = achievement.isUnlocked;

    return InkWell(
      onTap: () {
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              unlocked
                  ? 'Unlocked ${_formatUnlockDate(achievement.unlockedAt!)} • ${definition.description}'
                  : definition.description,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: pt.surfaceDim.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unlocked
                ? pt.goldPrimary.withValues(alpha: 0.55)
                : pt.borderSubtle.withValues(alpha: 0.4),
          ),
          boxShadow: unlocked
              ? [
                  BoxShadow(
                    color: pt.goldPrimary.withValues(alpha: 0.18),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked
                        ? pt.goldPrimary.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.04),
                  ),
                  child: Icon(
                    definition.icon,
                    size: 22,
                    color: unlocked
                        ? pt.goldPrimary
                        : pt.textMuted.withValues(alpha: 0.55),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  definition.title,
                  style: textTheme.titleSmall?.copyWith(
                    color: unlocked
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  unlocked
                      ? 'Unlocked'
                      : 'Locked',
                  style: textTheme.labelSmall?.copyWith(
                    color: unlocked ? pt.goldLight : pt.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
            if (!unlocked)
              Positioned(
                top: 0,
                right: 0,
                child: Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: pt.textMuted.withValues(alpha: 0.65),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
