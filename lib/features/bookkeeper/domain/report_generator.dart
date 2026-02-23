import 'package:intl/intl.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/features/bookkeeper/domain/session_stats.dart';

class ReportGenerator {
  static final _monthFormat = DateFormat('yyyy-MM');

  static SessionStats generate(List<Session> sessions) {
    if (sessions.isEmpty) {
      return SessionStats.empty;
    }

    double totalProfit = 0;
    double totalHoursPlayed = 0;
    int winningSessionCount = 0;
    double biggestWin = 0;
    double biggestLoss = 0;
    final Map<String, double> profitByMonth = {};

    for (final session in sessions) {
      totalProfit += session.profitLoss;
      totalHoursPlayed += session.hoursPlayed;

      if (session.profitLoss > 0) {
        winningSessionCount++;
      }

      if (session.profitLoss > biggestWin) {
        biggestWin = session.profitLoss;
      }
      if (session.profitLoss < biggestLoss) {
        biggestLoss = session.profitLoss;
      }

      final monthKey = _monthFormat.format(session.date);
      profitByMonth[monthKey] = (profitByMonth[monthKey] ?? 0) + session.profitLoss;
    }

    final hourlyRate =
        totalHoursPlayed > 0 ? totalProfit / totalHoursPlayed : 0.0;
    final winRate = sessions.isNotEmpty
        ? (winningSessionCount / sessions.length) * 100
        : 0.0;

    // Sort profitByMonth by key (chronological order)
    final sortedProfitByMonth = Map.fromEntries(
      profitByMonth.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return SessionStats(
      totalProfit: totalProfit,
      hourlyRate: hourlyRate,
      winRate: winRate,
      sessionCount: sessions.length,
      winningSessionCount: winningSessionCount,
      biggestWin: biggestWin,
      biggestLoss: biggestLoss,
      totalHoursPlayed: totalHoursPlayed,
      profitByMonth: sortedProfitByMonth,
    );
  }
}
