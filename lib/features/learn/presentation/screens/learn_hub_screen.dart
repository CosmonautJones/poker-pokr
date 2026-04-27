import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/trainer/domain/poker_glossary.dart';

/// Top-level "Learn" destination — a hub of bite-sized poker reference
/// screens (Hand Rankings, Positions, Pot Odds, Glossary).
///
/// Every card animates in on first paint and gives haptic feedback on tap so
/// the surface feels alive without external assets.
class LearnHubScreen extends ConsumerWidget {
  const LearnHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    final cards = <_LearnCardData>[
      _LearnCardData(
        title: 'Hand Rankings',
        subtitle: 'Royal flush down to high card',
        icon: Icons.style_rounded,
        accent: pt.goldPrimary,
        route: '/learn/hand-rankings',
      ),
      _LearnCardData(
        title: 'Positions',
        subtitle: '6-max & 9-max chart — early, middle, late, blinds',
        icon: Icons.crop_free_rounded,
        accent: pt.positionLate,
        route: '/learn/positions',
      ),
      _LearnCardData(
        title: 'Pot Odds',
        subtitle: 'Quick math + bet-size reference',
        icon: Icons.calculate_rounded,
        accent: pt.accent,
        route: '/learn/pot-odds',
      ),
      _LearnCardData(
        title: 'Glossary',
        subtitle: '${PokerGlossary.entries.length} terms across '
            '${PokerGlossary.categories.length} categories',
        icon: Icons.menu_book_rounded,
        accent: pt.seatActiveBorder,
        route: '/learn/glossary',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Responsive.hPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _Header(pt: pt, textTheme: textTheme),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final card = cards[i];
                    return _LearnCard(
                      data: card,
                      onTap: () {
                        ref.read(hapticServiceProvider).selection();
                        context.go(card.route);
                      },
                    )
                        .animate()
                        .fadeIn(
                            duration: 320.ms, delay: (60 + i * 60).ms)
                        .slideY(
                            begin: 0.05,
                            duration: 320.ms,
                            delay: (60 + i * 60).ms);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PokerTheme pt;
  final TextTheme textTheme;

  const _Header({required this.pt, required this.textTheme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [pt.accent, pt.goldDark],
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: pt.accent.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Learn',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Reference for every street',
                style: textTheme.bodySmall?.copyWith(
                  color: pt.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LearnCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final String route;

  const _LearnCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.route,
  });
}

class _LearnCard extends StatelessWidget {
  final _LearnCardData data;
  final VoidCallback onTap;

  const _LearnCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: data.accent.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: data.accent.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                data.accent.withValues(alpha: 0.10),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      data.accent.withValues(alpha: 0.30),
                      data.accent.withValues(alpha: 0.06),
                    ],
                  ),
                  border: Border.all(
                    color: data.accent.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(data.icon, size: 22, color: data.accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: pt.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 18,
                color: data.accent.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
