import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/features/bookkeeper/domain/report_generator.dart';
import 'package:poker_trainer/features/bookkeeper/domain/session_stats.dart';

/// Helper to create a test Session data class without a database.
Session _session({
  int id = 1,
  required DateTime date,
  double profitLoss = 0,
  double hoursPlayed = 1,
  double buyIn = 100,
  double cashOut = 100,
  String location = 'Test',
  String stakes = '1/2',
}) {
  return Session(
    id: id,
    date: date,
    gameType: 0,
    format: 0,
    location: location,
    stakes: stakes,
    buyIn: buyIn,
    cashOut: cashOut,
    profitLoss: profitLoss,
    hoursPlayed: hoursPlayed,
    notes: null,
    createdAt: date,
    updatedAt: date,
  );
}

void main() {
  group('ReportGenerator', () {
    test('returns empty stats for empty session list', () {
      final stats = ReportGenerator.generate([]);
      expect(stats.sessionCount, 0);
      expect(stats.totalProfit, 0);
      expect(stats.hourlyRate, 0);
      expect(stats.winRate, 0);
      expect(stats.biggestWin, 0);
      expect(stats.biggestLoss, 0);
      expect(stats.totalHoursPlayed, 0);
      expect(stats.profitByMonth, isEmpty);
    });

    test('calculates total profit from multiple sessions', () {
      final sessions = [
        _session(id: 1, date: DateTime(2024, 1, 1), profitLoss: 100),
        _session(id: 2, date: DateTime(2024, 1, 15), profitLoss: -50),
        _session(id: 3, date: DateTime(2024, 2, 1), profitLoss: 200),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.totalProfit, 250);
    });

    test('counts winning sessions correctly', () {
      final sessions = [
        _session(id: 1, date: DateTime(2024, 1, 1), profitLoss: 100),
        _session(id: 2, date: DateTime(2024, 1, 2), profitLoss: -50),
        _session(id: 3, date: DateTime(2024, 1, 3), profitLoss: 0),
        _session(id: 4, date: DateTime(2024, 1, 4), profitLoss: 25),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.sessionCount, 4);
      expect(stats.winningSessionCount, 2); // 100 and 25
    });

    test('calculates win rate as percentage', () {
      final sessions = [
        _session(id: 1, date: DateTime(2024, 1, 1), profitLoss: 100),
        _session(id: 2, date: DateTime(2024, 1, 2), profitLoss: -50),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.winRate, 50.0);
    });

    test('calculates hourly rate', () {
      final sessions = [
        _session(
          id: 1,
          date: DateTime(2024, 1, 1),
          profitLoss: 100,
          hoursPlayed: 5,
        ),
        _session(
          id: 2,
          date: DateTime(2024, 1, 2),
          profitLoss: -50,
          hoursPlayed: 5,
        ),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.hourlyRate, 5.0); // 50 profit / 10 hours
      expect(stats.totalHoursPlayed, 10.0);
    });

    test('handles zero hours played without division error', () {
      final sessions = [
        _session(
          id: 1,
          date: DateTime(2024, 1, 1),
          profitLoss: 100,
          hoursPlayed: 0,
        ),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.hourlyRate, 0.0);
    });

    test('tracks biggest win and loss', () {
      final sessions = [
        _session(id: 1, date: DateTime(2024, 1, 1), profitLoss: 500),
        _session(id: 2, date: DateTime(2024, 1, 2), profitLoss: -300),
        _session(id: 3, date: DateTime(2024, 1, 3), profitLoss: 200),
        _session(id: 4, date: DateTime(2024, 1, 4), profitLoss: -100),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.biggestWin, 500);
      expect(stats.biggestLoss, -300);
    });

    test('biggest win is 0 when all sessions are losses', () {
      final sessions = [
        _session(id: 1, date: DateTime(2024, 1, 1), profitLoss: -100),
        _session(id: 2, date: DateTime(2024, 1, 2), profitLoss: -50),
      ];
      final stats = ReportGenerator.generate(sessions);
      expect(stats.biggestWin, 0);
      expect(stats.biggestLoss, -100);
    });

    group('profitByMonth', () {
      test('groups sessions by month', () {
        final sessions = [
          _session(id: 1, date: DateTime(2024, 1, 5), profitLoss: 100),
          _session(id: 2, date: DateTime(2024, 1, 20), profitLoss: 50),
          _session(id: 3, date: DateTime(2024, 2, 10), profitLoss: -75),
        ];
        final stats = ReportGenerator.generate(sessions);
        expect(stats.profitByMonth, {
          '2024-01': 150.0,
          '2024-02': -75.0,
        });
      });

      test('months are sorted chronologically', () {
        // Feed sessions out of order.
        final sessions = [
          _session(id: 1, date: DateTime(2024, 3, 1), profitLoss: 30),
          _session(id: 2, date: DateTime(2024, 1, 1), profitLoss: 10),
          _session(id: 3, date: DateTime(2024, 2, 1), profitLoss: 20),
        ];
        final stats = ReportGenerator.generate(sessions);
        expect(stats.profitByMonth.keys.toList(), [
          '2024-01',
          '2024-02',
          '2024-03',
        ]);
      });

      test('single session per month', () {
        final sessions = [
          _session(id: 1, date: DateTime(2024, 6, 15), profitLoss: 250),
        ];
        final stats = ReportGenerator.generate(sessions);
        expect(stats.profitByMonth, {'2024-06': 250.0});
      });
    });
  });

  group('SessionStats', () {
    test('empty constant has all zero values', () {
      const stats = SessionStats.empty;
      expect(stats.totalProfit, 0);
      expect(stats.sessionCount, 0);
      expect(stats.profitByMonth, isEmpty);
    });
  });
}
