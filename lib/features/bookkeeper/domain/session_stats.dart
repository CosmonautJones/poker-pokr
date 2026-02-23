class SessionStats {
  final double totalProfit;
  final double hourlyRate;
  final double winRate;
  final int sessionCount;
  final int winningSessionCount;
  final double biggestWin;
  final double biggestLoss;
  final double totalHoursPlayed;
  final Map<String, double> profitByMonth;

  const SessionStats({
    required this.totalProfit,
    required this.hourlyRate,
    required this.winRate,
    required this.sessionCount,
    required this.winningSessionCount,
    required this.biggestWin,
    required this.biggestLoss,
    required this.totalHoursPlayed,
    required this.profitByMonth,
  });

  static const empty = SessionStats(
    totalProfit: 0,
    hourlyRate: 0,
    winRate: 0,
    sessionCount: 0,
    winningSessionCount: 0,
    biggestWin: 0,
    biggestLoss: 0,
    totalHoursPlayed: 0,
    profitByMonth: {},
  );
}
