import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_icons.dart';

/// Gallery of every achievement the player can earn.
///
/// Unlocked entries are shown in full color with their rarity tint; locked
/// entries are grayed out and show a lock icon. An inline summary at the
/// top shows "X / Y" progress so the player always knows how much is left.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final stats = ref.watch(userStatsProvider);
    final unlockedIds = stats.unlockedAchievementIds;
    final total = achievementsCatalog.length;
    final unlocked = achievementsCatalog
        .where((a) => unlockedIds.contains(a.id))
        .length;

    // Sort: unlocked first (most recent-looking), then by rarity ascending.
    final sorted = [...achievementsCatalog]..sort((a, b) {
        final ua = unlockedIds.contains(a.id);
        final ub = unlockedIds.contains(b.id);
        if (ua != ub) return ua ? -1 : 1;
        return a.rarity.index.compareTo(b.rarity.index);
      });

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _SummaryCard(unlocked: unlocked, total: total)
              .animate()
              .fadeIn(duration: 250.ms)
              .slideY(begin: 0.04, duration: 250.ms),
          const SizedBox(height: 14),
          for (var i = 0; i < sorted.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AchievementTile(
                achievement: sorted[i],
                unlocked: unlockedIds.contains(sorted[i].id),
              )
                  .animate()
                  .fadeIn(
                    duration: 250.ms,
                    delay: (60 * (i + 1)).clamp(0, 600).ms,
                  )
                  .slideY(
                    begin: 0.03,
                    duration: 250.ms,
                    delay: (60 * (i + 1)).clamp(0, 600).ms,
                  ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'More achievements coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: pt.textMuted.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int unlocked;
  final int total;

  const _SummaryCard({required this.unlocked, required this.total});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final pct = total == 0 ? 0.0 : unlocked / total;

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
                Icon(Icons.emoji_events_rounded,
                    color: pt.goldPrimary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Collection',
                  style: TextStyle(
                    color: pt.goldPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Text(
                  '$unlocked / $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
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
    final rarityColor = _rarityColor(pt, achievement.rarity);
    final tint = unlocked ? rarityColor : pt.textMuted;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: unlocked
              ? rarityColor.withValues(alpha: 0.5)
              : pt.borderSubtle.withValues(alpha: 0.3),
          width: unlocked ? 1.2 : 1,
        ),
      ),
      child: Opacity(
        opacity: unlocked ? 1.0 : 0.55,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tint.withValues(alpha: unlocked ? 0.45 : 0.2),
                      tint.withValues(alpha: 0.05),
                    ],
                  ),
                  border: Border.all(
                    color: tint.withValues(alpha: unlocked ? 0.8 : 0.35),
                    width: 1.2,
                  ),
                ),
                child: Icon(
                  unlocked
                      ? achievementIcon(achievement.iconCodePoint)
                      : Icons.lock_rounded,
                  color: unlocked ? Colors.white : pt.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            achievement.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _RarityChip(
                          rarity: achievement.rarity,
                          color: rarityColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: pt.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (unlocked)
                Icon(
                  Icons.check_circle_rounded,
                  color: rarityColor,
                  size: 20,
                )
              else
                Icon(
                  Icons.lock_outline_rounded,
                  color: pt.textMuted,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _rarityColor(PokerTheme pt, AchievementRarity r) {
    switch (r) {
      case AchievementRarity.common:
        return pt.profit;
      case AchievementRarity.rare:
        return pt.seatActiveBorder;
      case AchievementRarity.epic:
        return pt.straddlePrimary;
      case AchievementRarity.legendary:
        return pt.goldPrimary;
    }
  }
}

class _RarityChip extends StatelessWidget {
  final AchievementRarity rarity;
  final Color color;

  const _RarityChip({required this.rarity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Text(
        rarity.label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
