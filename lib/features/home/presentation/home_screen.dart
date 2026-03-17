import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/bookkeeper/providers/reports_provider.dart';
import 'package:poker_trainer/features/bookkeeper/providers/sessions_provider.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _quickDeal(BuildContext context, WidgetRef ref) {
    final setup = HandSetup.defaults(playerCount: 6);
    ref.read(activeHandSetupProvider.notifier).state = setup;
    context.go('/trainer/replay/0');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final sessionsAsync = ref.watch(sessionsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: Responsive.hPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Compact header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pt.goldPrimary, pt.goldDark],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.insights,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Table',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'Sense',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: pt.goldPrimary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Quick Deal — primary action
              _QuickDealCard(
                onTap: () => _quickDeal(context, ref),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 50.ms)
                  .slideY(begin: 0.04, duration: 300.ms, delay: 50.ms),

              const SizedBox(height: 14),

              // Last session card
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return _EmptySessionCard(
                      onTap: () => context.go('/bookkeeper/add'),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 150.ms)
                        .slideY(begin: 0.04, duration: 300.ms, delay: 150.ms);
                  }
                  final last = sessions.first;
                  return _LastSessionCard(
                    date: DateFormatter.formatDate(last.date),
                    location: last.location,
                    profitLoss: last.profitLoss,
                    onTap: () => context.go('/bookkeeper'),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 150.ms)
                      .slideY(begin: 0.04, duration: 300.ms, delay: 150.ms);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const SizedBox(height: 14),

              // Quick links row
              Row(
                children: [
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.add_circle_rounded,
                      label: 'New Hand',
                      color: pt.accent,
                      onTap: () => context.go('/trainer/create'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.school_rounded,
                      label: 'Lessons',
                      color: pt.seatActiveBorder,
                      onTap: () => context.go('/trainer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.note_add_rounded,
                      label: 'Log Session',
                      color: pt.goldPrimary,
                      onTap: () => context.go('/bookkeeper/add'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 250.ms)
                  .slideY(begin: 0.04, duration: 300.ms, delay: 250.ms),

              const SizedBox(height: 14),

              // Dynamic content: sparkline when sessions exist, tip otherwise
              sessionsAsync.when(
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return const _TipOfTheDay()
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 350.ms)
                        .slideY(begin: 0.04, duration: 300.ms, delay: 350.ms);
                  }
                  final stats = ref.watch(reportsProvider);
                  return stats.when(
                    data: (s) => _BankrollSparkline(
                      profitByMonth: s.profitByMonth,
                      onTap: () => context.go('/bookkeeper'),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 350.ms)
                        .slideY(
                            begin: 0.04, duration: 300.ms, delay: 350.ms),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const _TipOfTheDay(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Prominent card that starts a practice hand immediately.
class _QuickDealCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuickDealCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 6,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: pt.goldPrimary.withValues(alpha: 0.15),
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick Deal',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '6-max \u2022 1/2 blinds \u2022 100BB deep',
                      style: textTheme.bodySmall?.copyWith(
                        color: pt.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [pt.profit, pt.feltCenter],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: pt.profit.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
              )
                  .animate(
                    onPlay: (c) => c.repeat(reverse: true),
                  )
                  .scaleXY(
                    begin: 1.0,
                    end: 1.06,
                    duration: 1800.ms,
                    curve: Curves.easeInOut,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows the most recent bookkeeper session.
class _LastSessionCard extends StatelessWidget {
  final String date;
  final String location;
  final double profitLoss;
  final VoidCallback onTap;

  const _LastSessionCard({
    required this.date,
    required this.location,
    required this.profitLoss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final isProfit = profitLoss >= 0;
    final color = isProfit ? pt.profit : pt.loss;
    final sign = isProfit ? '+' : '';
    final formatted = profitLoss == profitLoss.roundToDouble()
        ? profitLoss.toStringAsFixed(0)
        : profitLoss.toStringAsFixed(2);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.history_rounded,
                size: 20,
                color: pt.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Session',
                      style: textTheme.labelSmall?.copyWith(
                        color: pt.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$location \u2022 $date',
                      style: textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                '$sign\$$formatted',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isProfit
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 18,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when no sessions have been logged yet.
class _EmptySessionCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptySessionCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.note_add_outlined,
                size: 20,
                color: pt.goldPrimary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Log your first session to track profits',
                  style: textTheme.bodySmall?.copyWith(
                    color: pt.textMuted,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: pt.goldPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small quick-action card for the link row.
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.06),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini bankroll chart shown when sessions exist.
class _BankrollSparkline extends StatelessWidget {
  final Map<String, double> profitByMonth;
  final VoidCallback onTap;

  const _BankrollSparkline({
    required this.profitByMonth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;

    if (profitByMonth.isEmpty) return const SizedBox.shrink();

    final entries = profitByMonth.entries.toList();
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int i = 0; i < entries.length; i++) {
      cumulative += entries[i].value;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    final yValues = spots.map((s) => s.y);
    final minY = yValues.reduce(math.min);
    final maxY = yValues.reduce(math.max);
    final yPad = ((maxY - minY).abs()) * 0.2;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: pt.borderSubtle.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 16, color: pt.goldPrimary),
                  const SizedBox(width: 6),
                  Text(
                    'Bankroll',
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: pt.textMuted),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (entries.length - 1).toDouble(),
                    minY: minY - yPad,
                    maxY: maxY + yPad,
                    extraLinesData: ExtraLinesData(
                      horizontalLines: [
                        HorizontalLine(
                          y: 0,
                          color: pt.textMuted.withValues(alpha: 0.2),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ],
                    ),
                    lineTouchData: const LineTouchData(enabled: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        preventCurveOverShooting: true,
                        color: pt.goldPrimary,
                        barWidth: 2.5,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: pt.goldPrimary.withValues(alpha: 0.08),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Daily rotating poker tip shown when no sessions are logged.
class _TipOfTheDay extends StatelessWidget {
  const _TipOfTheDay();

  static const _tips = [
    'Position is power. The later you act, the more information you have.',
    'Bet sizing tells a story. Make sure yours is consistent.',
    'Bankroll management is the #1 skill that separates pros from amateurs.',
    'Play the player, not just the cards. Watch for betting patterns.',
    'Fold equity is real equity. A well-timed bluff prints money.',
    "Don't chase draws without the right pot odds. Math doesn't lie.",
    'Review your biggest losses. Leaks hide in hands you want to forget.',
    'Table selection is an underrated edge. Pick your spots wisely.',
    'Tilt costs more than bad cards ever will. Protect your mental game.',
    'Small ball poker reduces variance and lets your edge compound.',
    'Think in ranges, not hands. Your opponents hold a distribution.',
    'Three-betting light from the blinds punishes weak openers.',
  ];

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final tip = _tips[DateTime.now().day % _tips.length];

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.goldPrimary.withValues(alpha: 0.06),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb_rounded,
              size: 18,
              color: pt.goldPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tip of the Day',
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.goldPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip,
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
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
