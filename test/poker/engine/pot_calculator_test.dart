import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/poker/models/pot.dart';
import 'package:poker_trainer/poker/engine/pot_calculator.dart';

void main() {
  group('PotCalculator.calculateSidePots', () {
    group('simple pot (no side pots)', () {
      test('everyone invested same amount produces one pot', () {
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 80, currentBet: 20, totalInvested: 20),
          PlayerState(index: 1, name: 'P1', stack: 80, currentBet: 20, totalInvested: 20),
          PlayerState(index: 2, name: 'P2', stack: 80, currentBet: 20, totalInvested: 20),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots.length, 1);
        expect(pots[0].amount, 60); // 3 * 20
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 1, 2]));
      });

      test('two players same investment', () {
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 90, currentBet: 10, totalInvested: 10),
          PlayerState(index: 1, name: 'P1', stack: 90, currentBet: 10, totalInvested: 10),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots.length, 1);
        expect(pots[0].amount, 20);
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 1]));
      });
    });

    group('one all-in creates a side pot', () {
      test('short-stacked player all-in creates main + side pot', () {
        // Player 0 goes all-in for 50, others call 100
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 0, currentBet: 50, totalInvested: 50, isAllIn: true),
          PlayerState(index: 1, name: 'P1', stack: 50, currentBet: 100, totalInvested: 100),
          PlayerState(index: 2, name: 'P2', stack: 50, currentBet: 100, totalInvested: 100),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots.length, 2);

        // Main pot: 50 * 3 = 150 (all three eligible)
        expect(pots[0].amount, 150);
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 1, 2]));

        // Side pot: 50 * 2 = 100 (only P1 and P2)
        expect(pots[1].amount, 100);
        expect(pots[1].eligiblePlayerIndices, containsAll([1, 2]));
        expect(pots[1].eligiblePlayerIndices, isNot(contains(0)));
      });
    });

    group('multiple all-ins at different levels', () {
      test('three different investment levels create three pots', () {
        // P0 all-in for 30, P1 all-in for 60, P2 invested 100
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 0, currentBet: 30, totalInvested: 30, isAllIn: true),
          PlayerState(index: 1, name: 'P1', stack: 0, currentBet: 60, totalInvested: 60, isAllIn: true),
          PlayerState(index: 2, name: 'P2', stack: 40, currentBet: 100, totalInvested: 100),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots.length, 3);

        // Main pot: 30 * 3 = 90 (all three eligible)
        expect(pots[0].amount, 90);
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 1, 2]));

        // Side pot 1: 30 * 2 = 60 (P1 and P2, each contribute 30 more)
        expect(pots[1].amount, 60);
        expect(pots[1].eligiblePlayerIndices, containsAll([1, 2]));
        expect(pots[1].eligiblePlayerIndices, isNot(contains(0)));

        // Side pot 2: 40 * 1 = 40 (only P2)
        expect(pots[2].amount, 40);
        expect(pots[2].eligiblePlayerIndices, [2]);
      });

      test('four players with two at same level and one short', () {
        // P0 all-in 20, P1 and P2 invested 50, P3 invested 50
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 0, totalInvested: 20, isAllIn: true),
          PlayerState(index: 1, name: 'P1', stack: 50, totalInvested: 50),
          PlayerState(index: 2, name: 'P2', stack: 50, totalInvested: 50),
          PlayerState(index: 3, name: 'P3', stack: 50, totalInvested: 50),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots.length, 2);

        // Main pot: 20 * 4 = 80
        expect(pots[0].amount, 80);
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 1, 2, 3]));

        // Side pot: 30 * 3 = 90 (P1, P2, P3 contribute 30 each beyond 20)
        expect(pots[1].amount, 90);
        expect(pots[1].eligiblePlayerIndices, containsAll([1, 2, 3]));
        expect(pots[1].eligiblePlayerIndices, isNot(contains(0)));
      });
    });

    group('folded players contribute but are not eligible', () {
      test('folded player chips go to pot but player is not eligible', () {
        // P0 folded after investing 20, P1 and P2 invested 50 each
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 80, totalInvested: 20, isFolded: true),
          PlayerState(index: 1, name: 'P1', stack: 50, totalInvested: 50),
          PlayerState(index: 2, name: 'P2', stack: 50, totalInvested: 50),
        ];

        final pots = PotCalculator.calculateSidePots(players);

        // P0's 20 chips go to the pot but P0 is not eligible
        // Main pot level at 50 (the only non-folded investment level)
        // P0 contributed 20, P1 contributes 50, P2 contributes 50 => total 120
        expect(pots.length, 1);
        expect(pots[0].amount, 120); // 20 + 50 + 50
        expect(pots[0].eligiblePlayerIndices, containsAll([1, 2]));
        expect(pots[0].eligiblePlayerIndices, isNot(contains(0)));
      });

      test('folded player invested more than an all-in player', () {
        // P0 all-in for 30, P1 folded after investing 50, P2 invested 100
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 0, totalInvested: 30, isAllIn: true),
          PlayerState(index: 1, name: 'P1', stack: 50, totalInvested: 50, isFolded: true),
          PlayerState(index: 2, name: 'P2', stack: 0, totalInvested: 100),
        ];

        final pots = PotCalculator.calculateSidePots(players);

        // Level 30: all 3 contribute 30 each -> main pot 90, eligible: P0, P2
        expect(pots[0].amount, 90);
        expect(pots[0].eligiblePlayerIndices, containsAll([0, 2]));

        // Level 100: P1 contributes 20 more (50-30), P2 contributes 70 more (100-30)
        // -> side pot 90, eligible: P2 only
        expect(pots[1].amount, 90);
        expect(pots[1].eligiblePlayerIndices, [2]);
      });
    });

    group('edge cases', () {
      test('no investments returns empty list', () {
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 100, totalInvested: 0),
          PlayerState(index: 1, name: 'P1', stack: 100, totalInvested: 0),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots, isEmpty);
      });

      test('all players folded returns empty list', () {
        final players = [
          PlayerState(index: 0, name: 'P0', stack: 80, totalInvested: 20, isFolded: true),
          PlayerState(index: 1, name: 'P1', stack: 80, totalInvested: 20, isFolded: true),
        ];

        final pots = PotCalculator.calculateSidePots(players);
        expect(pots, isEmpty);
      });
    });
  });
}
