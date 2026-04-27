import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/learn/domain/hand_rankings.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/community_cards.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// Visual reference of the ten poker hand categories, strongest first.
///
/// Each row uses [MiniCardWidget] so the example hand reads exactly like
/// cards do in the live trainer. Rank colour intensity fades from gold
/// (royal flush) to muted (high card).
class HandRankingsScreen extends StatelessWidget {
  const HandRankingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hand Rankings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/learn'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: Responsive.hPadding(context).add(
            const EdgeInsets.only(top: 8, bottom: 24),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Stronger to weaker. Numbers show the chance of being dealt '
                'each category in a 5-card hand.',
                style: textTheme.bodySmall?.copyWith(
                  color: pt.textMuted,
                  height: 1.4,
                ),
              ),
            ),
            for (var i = 0; i < HandRankings.all.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RankingTile(
                  ranking: HandRankings.all[i],
                  goldFactor: 1.0 - (i / HandRankings.all.length),
                )
                    .animate()
                    .fadeIn(duration: 280.ms, delay: (40 + i * 40).ms)
                    .slideY(
                        begin: 0.04,
                        duration: 280.ms,
                        delay: (40 + i * 40).ms),
              ),
          ],
        ),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  final HandRanking ranking;

  /// 1.0 for the strongest hand, ~0 for the weakest. Drives accent intensity.
  final double goldFactor;

  const _RankingTile({required this.ranking, required this.goldFactor});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final accent = Color.lerp(pt.textMuted, pt.goldPrimary, goldFactor)!;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accent.withValues(alpha: 0.06),
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
                _RankBadge(rank: ranking.rank, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ranking.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ranking.summary,
                        style: textTheme.bodySmall?.copyWith(
                          color: pt.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                _ProbabilityBadge(percent: ranking.probabilityPercent),
              ],
            ),
            const SizedBox(height: 12),
            _ExampleHand(cards: ranking.example),
            const SizedBox(height: 10),
            Text(
              ranking.description,
              style: textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color color;

  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _ProbabilityBadge extends StatelessWidget {
  final double percent;

  const _ProbabilityBadge({required this.percent});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final label = percent < 0.01
        ? '<0.01%'
        : percent < 1
            ? '${percent.toStringAsFixed(2)}%'
            : '${percent.toStringAsFixed(1)}%';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: pt.surfaceDim,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: pt.borderSubtle.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: pt.textMuted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ExampleHand extends StatelessWidget {
  final List<PokerCard> cards;

  const _ExampleHand({required this.cards});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (var i = 0; i < cards.length; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
              child: MiniCardWidget(card: cards[i], scale: 1.15),
            ),
        ],
      ),
    );
  }
}
