import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';
import 'package:poker_trainer/features/achievements/presentation/achievement_visuals.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(achievementsProvider);
    final total = AchievementCatalog.all.length;
    final unlocked = state.unlockedCount;
    final progress = total == 0 ? 0.0 : unlocked / total;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _ProgressHeader(
            unlocked: unlocked,
            total: total,
            progress: progress,
          ),
          const SizedBox(height: 20),
          for (final cat in AchievementCategory.values)
            _CategorySection(
              title: categoryLabel(cat),
              items: AchievementCatalog.inCategory(cat),
              state: state,
              theme: pt,
              textTheme: textTheme,
            ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int unlocked;
  final int total;
  final double progress;

  const _ProgressHeader({
    required this.unlocked,
    required this.total,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            pt.goldPrimary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: pt.goldPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Collection',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$unlocked / $total',
                style: textTheme.titleSmall?.copyWith(
                  color: pt.goldPrimary,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
    );
  }
}

class _CategorySection extends StatelessWidget {
  final String title;
  final List<AchievementDef> items;
  final AchievementsState state;
  final PokerTheme theme;
  final TextTheme textTheme;

  const _CategorySection({
    required this.title,
    required this.items,
    required this.state,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final unlockedHere = items.where((d) => state.isUnlocked(d.id)).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Text(
                title,
                style: textTheme.labelLarge?.copyWith(
                  color: theme.goldPrimary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$unlockedHere / ${items.length}',
                style: textTheme.labelSmall?.copyWith(
                  color: theme.textMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        for (final def in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _AchievementTile(
              def: def,
              unlockedAt: state.unlocked[def.id],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDef def;
  final DateTime? unlockedAt;

  const _AchievementTile({required this.def, required this.unlockedAt});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final unlocked = unlockedAt != null;
    final style = TierStyle.of(context, def.tier);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: unlocked
            ? pt.surfaceDim.withValues(alpha: 0.6)
            : pt.surfaceDim.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked
              ? style.accent.withValues(alpha: 0.4)
              : pt.borderSubtle.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AchievementMedallion(def: def, unlocked: unlocked, size: 48),
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
                        def.title,
                        style: textTheme.bodyLarge?.copyWith(
                          color: unlocked
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: unlocked
                            ? style.accent.withValues(alpha: 0.18)
                            : pt.borderSubtle.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        style.label.toUpperCase(),
                        style: TextStyle(
                          color: unlocked
                              ? style.accent
                              : pt.textMuted.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unlocked ? def.description : def.hint,
                  style: textTheme.bodySmall?.copyWith(
                    color: unlocked
                        ? pt.textMuted
                        : pt.textMuted.withValues(alpha: 0.6),
                    height: 1.3,
                    fontStyle:
                        unlocked ? FontStyle.normal : FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (unlocked) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unlocked ${DateFormatter.formatDate(unlockedAt!)}',
                    style: textTheme.labelSmall?.copyWith(
                      color: style.accent.withValues(alpha: 0.85),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
