import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/learn/domain/pot_odds.dart';

void main() {
  group('computePotOdds', () {
    test('half-pot bet → 25% break-even equity', () {
      // Pot was 100, villain bets 50, you call 50 into a 150 pot.
      final odds = computePotOdds(potBeforeCall: 150, toCall: 50);
      expect(odds.breakEvenEquity, closeTo(0.25, 0.001));
      expect(odds.ratio, closeTo(3.0, 0.001));
    });

    test('pot-sized bet → 33.3% break-even equity', () {
      // Pot 100, villain bets 100. You call 100 into a 200 pot.
      final odds = computePotOdds(potBeforeCall: 200, toCall: 100);
      expect(odds.breakEvenEquity, closeTo(1 / 3, 0.001));
      expect(odds.ratio, closeTo(2.0, 0.001));
    });

    test('zero or negative call returns zeroes (no division by zero)', () {
      final odds = computePotOdds(potBeforeCall: 100, toCall: 0);
      expect(odds.breakEvenEquity, 0);
      expect(odds.ratio, 0);
    });

    test('formatted labels match expected shape', () {
      final odds = computePotOdds(potBeforeCall: 150, toCall: 50);
      expect(odds.ratioLabel, '3.0 : 1');
      expect(odds.equityPercentLabel, '25.0%');
    });
  });

  group('PotOddsReference', () {
    test('half-pot row matches manual calculation', () {
      final row = PotOddsReference.rows
          .firstWhere((r) => r.betFractionOfPot == 0.5);
      // bet = 0.5 pot, call into 1.5 pot, need 0.5/2.0 = 25%
      expect(row.breakEvenEquity, closeTo(0.25, 0.001));
    });

    test('overbets demand more equity than half-pot', () {
      final half = PotOddsReference.rows
          .firstWhere((r) => r.betFractionOfPot == 0.5);
      final overbet = PotOddsReference.rows
          .firstWhere((r) => r.betFractionOfPot == 2.0);
      expect(overbet.breakEvenEquity, greaterThan(half.breakEvenEquity));
    });

    test('break-even equity is monotonic in bet size', () {
      final sorted = [...PotOddsReference.rows]
        ..sort((a, b) => a.betFractionOfPot.compareTo(b.betFractionOfPot));
      for (var i = 1; i < sorted.length; i++) {
        expect(sorted[i].breakEvenEquity,
            greaterThan(sorted[i - 1].breakEvenEquity),
            reason: 'larger bets should require more equity');
      }
    });
  });

  group('ruleOfTwoAndFour', () {
    test('flush draw on the flop ≈ 36% equity (9 outs × 4)', () {
      final eq = PotOddsReference.ruleOfTwoAndFour(
          outs: 9, flopWithTwoToCome: true);
      expect(eq, closeTo(0.36, 0.001));
    });

    test('flush draw on the turn ≈ 18% equity (9 outs × 2)', () {
      final eq = PotOddsReference.ruleOfTwoAndFour(
          outs: 9, flopWithTwoToCome: false);
      expect(eq, closeTo(0.18, 0.001));
    });

    test('clamps at 100% for high out counts', () {
      final eq = PotOddsReference.ruleOfTwoAndFour(
          outs: 30, flopWithTwoToCome: true);
      expect(eq, lessThanOrEqualTo(1.0));
      expect(eq, 1.0);
    });
  });
}
