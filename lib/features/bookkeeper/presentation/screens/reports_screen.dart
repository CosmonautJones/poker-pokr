import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/utils/currency_formatter.dart';
import 'package:poker_trainer/features/bookkeeper/domain/session_stats.dart';
import 'package:poker_trainer/features/bookkeeper/presentation/widgets/profit_chart.dart';
import 'package:poker_trainer/features/bookkeeper/presentation/widgets/stats_summary_card.dart';
import 'package:poker_trainer/features/bookkeeper/providers/reports_provider.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        data: (stats) => _ReportsBody(stats: stats),
      ),
    );
  }
}

class _ReportsBody extends StatelessWidget {
  final SessionStats stats;

  const _ReportsBody({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (stats.sessionCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 64,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No data yet',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Log some sessions to see your stats here.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final totalProfitColor = stats.totalProfit >= 0
        ? Colors.green.shade400
        : Colors.red.shade400;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // Summary cards grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            StatsSummaryCard(
              title: 'Total Profit',
              value: CurrencyFormatter.formatSigned(stats.totalProfit),
              icon: Icons.attach_money,
              valueColor: totalProfitColor,
            ),
            StatsSummaryCard(
              title: 'Hourly Rate',
              value: '${CurrencyFormatter.formatSigned(stats.hourlyRate)}/hr',
              icon: Icons.access_time,
              valueColor: stats.hourlyRate >= 0
                  ? Colors.green.shade400
                  : Colors.red.shade400,
            ),
            StatsSummaryCard(
              title: 'Sessions Played',
              value: stats.sessionCount.toString(),
              icon: Icons.casino_outlined,
            ),
            StatsSummaryCard(
              title: 'Win Rate',
              value: '${stats.winRate.toStringAsFixed(1)}%',
              icon: Icons.percent,
              valueColor: stats.winRate >= 50
                  ? Colors.green.shade400
                  : Colors.orange.shade400,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Additional stats row
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            StatsSummaryCard(
              title: 'Biggest Win',
              value: CurrencyFormatter.format(stats.biggestWin),
              icon: Icons.trending_up_rounded,
              valueColor: Colors.green.shade400,
            ),
            StatsSummaryCard(
              title: 'Biggest Loss',
              value: CurrencyFormatter.format(stats.biggestLoss),
              icon: Icons.trending_down_rounded,
              valueColor: Colors.red.shade400,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Total hours
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: StatsSummaryCard(
            title: 'Total Hours Played',
            value: '${stats.totalHoursPlayed.toStringAsFixed(1)}h',
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(height: 16),

        // Profit chart
        if (stats.profitByMonth.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Cumulative Profit Over Time',
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ProfitChart(profitByMonth: stats.profitByMonth),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }
}
