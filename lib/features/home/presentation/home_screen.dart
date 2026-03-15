import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/date_formatter.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
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
                      Icons.casino,
                      size: 22,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        colors: [pt.goldLight, pt.goldPrimary, pt.goldLight],
                      ).createShader(bounds);
                    },
                    child: Text(
                      'Poker Trainer',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
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
                      icon: Icons.add_circle_outline,
                      label: 'New Hand',
                      onTap: () => context.go('/trainer/create'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.school_rounded,
                      label: 'Lessons',
                      onTap: () => context.go('/trainer'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.note_add_outlined,
                      label: 'Log Session',
                      onTap: () => context.go('/bookkeeper/add'),
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 250.ms)
                  .slideY(begin: 0.04, duration: 300.ms, delay: 250.ms),

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
          color: pt.profit.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        splashColor: pt.profit.withValues(alpha: 0.15),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pt.profit.withValues(alpha: 0.12),
                pt.surfaceDim,
              ],
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
                    colors: [pt.profit, pt.profit.withValues(alpha: 0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: pt.profit.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 28,
                  color: Colors.white,
                ),
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
  final VoidCallback onTap;

  const _QuickLink({
    required this.icon,
    required this.label,
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
          color: pt.borderSubtle.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: pt.goldPrimary),
              const SizedBox(height: 6),
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
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
