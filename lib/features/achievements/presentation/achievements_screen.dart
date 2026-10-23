import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Full-screen badges gallery. Displays every achievement with
/// locked/unlocked state and lets the player tap any tile for the
/// description.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = ref.watch(achievementsProvider);
    final total = kAchievements.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Badges'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: _GalleryHeader(
                  unlocked: unlocked.length,
                  total: total,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              sliver: SliverGrid(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final a = kAchievements[index];
                    final isUnlocked = unlocked.contains(a.id);
                    return _BadgeTile(
                      achievement: a,
                      unlocked: isUnlocked,
                      onTap: () {
                        ref.read(hapticServiceProvider).selection();
                        _showDetails(context, a, isUnlocked);
                      },
                    )
                        .animate()
                        .fadeIn(
                          duration: 220.ms,
                          delay: (40 * index).ms,
                        )
                        .slideY(
                          begin: 0.06,
                          duration: 220.ms,
                          delay: (40 * index).ms,
                        );
                  },
                  childCount: kAchievements.length,
                ),
              ),
            ),
            if (unlocked.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 24),
                  child: Text(
                    "Play hands and complete lessons to unlock badges.",
                    style: textTheme.bodySmall?.copyWith(
                      color: pt.textMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(
    BuildContext context,
    Achievement a,
    bool unlocked,
  ) {
    final pt = context.poker;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pt.surfaceDim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final textTheme = Theme.of(sheetContext).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          (unlocked ? pt.goldPrimary : pt.textMuted)
                              .withValues(alpha: 0.32),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: (unlocked ? pt.goldPrimary : pt.textMuted)
                            .withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      a.icon,
                      size: 30,
                      color: unlocked ? pt.goldPrimary : pt.textMuted,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.title,
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unlocked ? 'Unlocked' : 'Locked',
                          style: textTheme.labelSmall?.copyWith(
                            color: unlocked ? pt.profit : pt.textMuted,
                            fontWeight: FontWeight.w600,
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
                a.description,
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

class _GalleryHeader extends StatelessWidget {
  final int unlocked;
  final int total;

  const _GalleryHeader({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final fraction = total == 0 ? 0.0 : unlocked / total;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.25),
          width: 1,
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
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 22,
                  color: pt.goldPrimary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Collection',
                    style: textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '$unlocked / $total',
                  style: textTheme.titleSmall?.copyWith(
                    color: pt.goldPrimary,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor:
                    AlwaysStoppedAnimation<Color>(pt.goldPrimary),
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
  final bool unlocked;
  final VoidCallback onTap;

  const _BadgeTile({
    required this.achievement,
    required this.unlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    final accent = unlocked ? pt.goldPrimary : pt.textMuted;
    final icon = achievement.icon;

    return Material(
      color: pt.surfaceDim,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: accent.withValues(alpha: unlocked ? 0.45 : 0.18),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          accent.withValues(
                              alpha: unlocked ? 0.32 : 0.10),
                          Colors.transparent,
                        ],
                      ),
                      border: Border.all(
                        color: accent.withValues(
                            alpha: unlocked ? 0.7 : 0.25),
                        width: 1.5,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 26,
                    color: unlocked
                        ? accent
                        : accent.withValues(alpha: 0.5),
                  ),
                  if (!unlocked)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: pt.surfaceDim,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: accent.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.lock_rounded,
                          size: 10,
                          color: accent.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                achievement.title,
                style: textTheme.labelSmall?.copyWith(
                  color: unlocked
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
