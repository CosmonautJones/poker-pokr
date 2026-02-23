import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:poker_trainer/core/utils/currency_formatter.dart';

class ProfitChart extends StatelessWidget {
  final Map<String, double> profitByMonth;

  const ProfitChart({
    super.key,
    required this.profitByMonth,
  });

  @override
  Widget build(BuildContext context) {
    if (profitByMonth.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data to display')),
      );
    }

    final theme = Theme.of(context);
    final entries = profitByMonth.entries.toList();

    // Build cumulative profit data
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int i = 0; i < entries.length; i++) {
      cumulative += entries[i].value;
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    // Calculate Y axis bounds with padding
    final yValues = spots.map((s) => s.y);
    final minY = yValues.reduce(math.min);
    final maxY = yValues.reduce(math.max);
    final yPadding = ((maxY - minY).abs()) * 0.15;
    final chartMinY = minY - yPadding;
    final chartMaxY = maxY + yPadding;

    return SizedBox(
      height: 240,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, top: 16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calculateInterval(chartMinY, chartMaxY),
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.surfaceContainerHighest,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    // Show every label if few months, otherwise skip some
                    if (entries.length > 6 && index % 2 != 0) {
                      return const SizedBox.shrink();
                    }
                    final monthKey = entries[index].key;
                    // Format "2024-01" to "Jan"
                    final month = int.tryParse(monthKey.substring(5)) ?? 1;
                    final label = _monthAbbreviation(month);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  interval: _calculateInterval(chartMinY, chartMaxY),
                  getTitlesWidget: (value, meta) {
                    return Text(
                      CurrencyFormatter.format(value),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (entries.length - 1).toDouble(),
            minY: chartMinY,
            maxY: chartMaxY,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                preventCurveOverShooting: true,
                color: Colors.green.shade400,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: Colors.green.shade400,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.shade400.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    theme.colorScheme.surfaceContainerHighest,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final monthKey =
                        index < entries.length ? entries[index].key : '';
                    return LineTooltipItem(
                      '$monthKey\n${CurrencyFormatter.formatSigned(spot.y)}',
                      TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateInterval(double minY, double maxY) {
    final range = (maxY - minY).abs();
    if (range == 0) return 100;
    // Aim for roughly 4-5 grid lines
    final rawInterval = range / 4;
    // Round to a nice number
    final magnitude = math.pow(10, (math.log(rawInterval) / math.ln10).floor());
    final normalized = rawInterval / magnitude;
    double niceInterval;
    if (normalized <= 1.5) {
      niceInterval = 1;
    } else if (normalized <= 3.5) {
      niceInterval = 2;
    } else if (normalized <= 7.5) {
      niceInterval = 5;
    } else {
      niceInterval = 10;
    }
    return niceInterval * magnitude;
  }

  static String _monthAbbreviation(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[(month - 1).clamp(0, 11)];
  }
}
