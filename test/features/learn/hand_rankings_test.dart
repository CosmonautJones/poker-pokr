import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/learn/domain/hand_rankings.dart';

void main() {
  group('HandRankings', () {
    test('contains all ten standard categories in strongest-first order', () {
      expect(HandRankings.all.length, 10);
      for (var i = 0; i < HandRankings.all.length; i++) {
        expect(HandRankings.all[i].rank, i + 1,
            reason: 'rank field should match position (1-indexed)');
      }
    });

    test('every example uses exactly five distinct cards', () {
      for (final h in HandRankings.all) {
        expect(h.example.length, 5,
            reason: '${h.name} should have 5 example cards');
        final values = h.example.map((c) => c.value).toSet();
        expect(values.length, 5,
            reason: '${h.name} example contains duplicate cards');
      }
    });

    test('byRank returns the matching entry', () {
      expect(HandRankings.byRank(1).name, 'Royal Flush');
      expect(HandRankings.byRank(10).name, 'High Card');
    });

    test('probabilities are positive and sum to roughly 100%', () {
      final total = HandRankings.all
          .map((h) => h.probabilityPercent)
          .fold<double>(0, (a, b) => a + b);
      // Categories are mutually exclusive — combined frequency ≈ 100%.
      expect(total, closeTo(100, 0.5));
      for (final h in HandRankings.all) {
        expect(h.probabilityPercent, greaterThan(0));
      }
    });
  });
}
