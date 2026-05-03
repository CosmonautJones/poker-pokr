import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/daily_challenge.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('buildDailyPool', () {
    test('produces a non-empty pool from the lessons catalog', () {
      final pool = buildDailyPool();
      expect(pool, isNotEmpty);
      // Catalog has at least one lesson with at least one scenario.
      expect(pool.first.lessonId, isNotEmpty);
      expect(pool.first.scenarioTitle, isNotEmpty);
    });

    test('every entry has matching ids and non-empty titles', () {
      for (final r in buildDailyPool()) {
        expect(r.lessonId, isNotEmpty);
        expect(r.scenarioIndex, greaterThanOrEqualTo(0));
        expect(r.lessonTitle, isNotEmpty);
        expect(r.scenarioTitle, isNotEmpty);
      }
    });
  });

  group('challengeFor', () {
    test('returns same selection for two different times same day', () {
      final morning = DateTime(2026, 5, 3, 8, 0);
      final night = DateTime(2026, 5, 3, 23, 30);
      final a = challengeFor(morning)!;
      final b = challengeFor(night)!;
      expect(a.lessonId, b.lessonId);
      expect(a.scenarioIndex, b.scenarioIndex);
    });

    test('rotates across pool length', () {
      final pool = buildDailyPool();
      final picks = <String>{};
      // Walk pool.length consecutive days; expect picks to cover the pool.
      var d = DateTime(2026, 1, 1);
      for (var i = 0; i < pool.length; i++) {
        final r = challengeFor(d)!;
        picks.add('${r.lessonId}::${r.scenarioIndex}');
        d = d.add(const Duration(days: 1));
      }
      expect(picks.length, pool.length);
    });

    test('returns null if pool is empty', () {
      final r = challengeFor(DateTime(2026, 1, 1), pool: const []);
      expect(r, isNull);
    });
  });

  group('isDailyChallengeDone', () {
    test('false when never completed', () {
      expect(
        isDailyChallengeDone(
          const UserStats.empty(),
          DateTime(2026, 5, 3),
        ),
        isFalse,
      );
    });

    test('true on the same calendar day, false on next', () {
      final stats = const UserStats.empty().copyWith(
        dailyChallengeLastCompletedDay: DateTime(2026, 5, 3),
      );
      expect(
        isDailyChallengeDone(stats, DateTime(2026, 5, 3, 23, 0)),
        isTrue,
      );
      expect(
        isDailyChallengeDone(stats, DateTime(2026, 5, 4, 0, 1)),
        isFalse,
      );
    });
  });
}
