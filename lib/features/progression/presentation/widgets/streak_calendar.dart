import 'package:flutter/material.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Compact 35-day heatmap showing which days the player was active. The
/// rightmost column is today; filled dots light up when the activity fell
/// on a day inside the current streak window, muted dots mean "logged play
/// but gap broke the streak", empty cells mean no play that day.
///
/// We only know the *current* streak and the most-recent play day from
/// [UserStats]. That's enough to infer the current-streak window; older
/// history isn't stored yet. The calendar is intentionally aspirational —
/// once per-day play logs land, we'll fill older cells too.
class StreakCalendar extends StatelessWidget {
  final UserStats stats;
  const StreakCalendar({super.key, required this.stats});

  static const _rows = 5;
  static const _cols = 7;
  static const _cellCount = _rows * _cols; // 35 days

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final today = _dateOnly(DateTime.now());

    // Precompute the set of in-streak days counting back from today.
    final inStreak = _activeStreakDays(stats, today);
    final lastPlayedDay = stats.lastPlayedDay == null
        ? null
        : _dateOnly(stats.lastPlayedDay!);

    // Layout: cellCount cells, oldest on the left, today on the right.
    final daysBack = List<DateTime>.generate(
      _cellCount,
      (i) => today.subtract(Duration(days: _cellCount - 1 - i)),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  size: 16,
                  color: stats.streakDays > 0 ? pt.allInGlow : pt.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  stats.streakDays > 0
                      ? '${stats.streakDays}-day streak'
                      : 'No active streak',
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  'last 35 days',
                  style: textTheme.labelSmall?.copyWith(
                    color: pt.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = 4.0;
                final cellW = (constraints.maxWidth - gap * (_cols - 1)) / _cols;
                final cellH = cellW.clamp(10.0, 22.0);
                return Column(
                  children: [
                    for (int r = 0; r < _rows; r++)
                      Padding(
                        padding: EdgeInsets.only(
                            top: r == 0 ? 0 : gap),
                        child: Row(
                          children: [
                            for (int c = 0; c < _cols; c++) ...[
                              if (c > 0) const SizedBox(width: gap),
                              _cell(
                                context,
                                daysBack[r * _cols + c],
                                inStreak: inStreak,
                                lastPlayedDay: lastPlayedDay,
                                today: today,
                                width: cellW,
                                height: cellH,
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    DateTime day, {
    required Set<DateTime> inStreak,
    required DateTime? lastPlayedDay,
    required DateTime today,
    required double width,
    required double height,
  }) {
    final pt = context.poker;
    final isToday = day == today;
    final isFuture = day.isAfter(today);
    final hit = inStreak.contains(day);

    Color fill;
    Color border;
    if (isFuture) {
      fill = Colors.transparent;
      border = pt.borderSubtle.withValues(alpha: 0.18);
    } else if (hit) {
      fill = pt.allInGlow.withValues(alpha: 0.85);
      border = pt.allInGlow.withValues(alpha: 0.95);
    } else if (lastPlayedDay != null && day == lastPlayedDay && !hit) {
      // Played but the streak broke since — muted amber.
      fill = pt.allInGlow.withValues(alpha: 0.25);
      border = pt.allInGlow.withValues(alpha: 0.4);
    } else {
      fill = Colors.white.withValues(alpha: 0.04);
      border = pt.borderSubtle.withValues(alpha: 0.22);
    }

    return Expanded(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isToday
                ? pt.goldPrimary.withValues(alpha: 0.85)
                : border,
            width: isToday ? 1.4 : 0.8,
          ),
        ),
      ),
    );
  }

  /// Infer the set of days covered by the player's *current* streak. If the
  /// streak is 0 or last-played is stale (>1 day gap), returns empty.
  static Set<DateTime> _activeStreakDays(UserStats stats, DateTime today) {
    if (stats.streakDays <= 0 || stats.lastPlayedDay == null) {
      return const <DateTime>{};
    }
    final last = _dateOnly(stats.lastPlayedDay!);
    final gap = today.difference(last).inDays;
    if (gap > 1) return const <DateTime>{};
    final out = <DateTime>{};
    for (int i = 0; i < stats.streakDays; i++) {
      out.add(last.subtract(Duration(days: i)));
    }
    return out;
  }

  static DateTime _dateOnly(DateTime ts) =>
      DateTime(ts.year, ts.month, ts.day);
}
