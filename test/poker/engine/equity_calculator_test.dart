import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/equity_calculator.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:poker_trainer/poker/models/player.dart';

PokerCard c(Rank rank, Suit suit) => PokerCard.from(rank, suit);

PlayerState player(int index, String name, List<PokerCard> holeCards) =>
    PlayerState(
      index: index,
      name: name,
      stack: 1000,
      holeCards: holeCards,
    );

void main() {
  group('EquityCalculator', () {
    test('single player returns 100% equity', () {
      final players = [
        player(0, 'Hero', [c(Rank.ace, Suit.spades), c(Rank.king, Suit.spades)]),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 100,
        seed: 42,
      );

      expect(result.playerEquities.length, 1);
      expect(result[0]!.winRate, 1.0);
    });

    test('folded players are excluded from equity', () {
      final players = [
        player(0, 'Hero', [c(Rank.ace, Suit.spades), c(Rank.king, Suit.spades)]),
        PlayerState(
          index: 1,
          name: 'Villain',
          stack: 1000,
          holeCards: [c(Rank.two, Suit.clubs), c(Rank.three, Suit.clubs)],
          isFolded: true,
        ),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 100,
        seed: 42,
      );

      expect(result.playerEquities.length, 1);
      expect(result[0]!.winRate, 1.0);
    });

    test('AA vs KK preflop — AA should have ~80% equity', () {
      final players = [
        player(0, 'AA', [c(Rank.ace, Suit.spades), c(Rank.ace, Suit.hearts)]),
        player(1, 'KK', [c(Rank.king, Suit.spades), c(Rank.king, Suit.hearts)]),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 5000,
        seed: 42,
      );

      expect(result.playerEquities.length, 2);
      final aaEquity = result[0]!.equity;
      final kkEquity = result[1]!.equity;

      // AA vs KK is approximately 80/20.
      expect(aaEquity, greaterThan(0.70));
      expect(aaEquity, lessThan(0.90));
      expect(kkEquity, greaterThan(0.10));
      expect(kkEquity, lessThan(0.30));

      // Equities should sum to approximately 1.0.
      expect(aaEquity + kkEquity, closeTo(1.0, 0.01));
    });

    test('complete board — deterministic result', () {
      // Hero has a flush, villain has a pair.
      final players = [
        player(0, 'Hero', [c(Rank.ace, Suit.hearts), c(Rank.king, Suit.hearts)]),
        player(1, 'Villain', [c(Rank.queen, Suit.spades), c(Rank.queen, Suit.clubs)]),
      ];

      final community = [
        c(Rank.two, Suit.hearts),
        c(Rank.five, Suit.hearts),
        c(Rank.nine, Suit.hearts),
        c(Rank.jack, Suit.clubs),
        c(Rank.three, Suit.diamonds),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: community,
        gameType: GameType.texasHoldem,
        simulations: 1000,
      );

      // Hero has nut flush — 100% winner.
      expect(result[0]!.winRate, 1.0);
      expect(result[1]!.winRate, 0.0);
    });

    test('tie scenario — identical hands split equity', () {
      // Both players have same hole cards (different suits), board makes best hand.
      final players = [
        player(0, 'P1', [c(Rank.two, Suit.clubs), c(Rank.three, Suit.clubs)]),
        player(1, 'P2', [c(Rank.two, Suit.diamonds), c(Rank.three, Suit.diamonds)]),
      ];

      // Board: AKQJT rainbow — both play the straight on the board.
      final community = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.spades),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.spades),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: community,
        gameType: GameType.texasHoldem,
      );

      // Both tie — tieRate should be 1.0 for each.
      expect(result[0]!.tieRate, 1.0);
      expect(result[1]!.tieRate, 1.0);
      expect(result[0]!.equity, closeTo(0.5, 0.01));
    });

    test('three-way tie on complete board — equities sum to 1.0', () {
      // Three players all play the board straight (AKQJT).
      final players = [
        player(0, 'P1', [c(Rank.two, Suit.clubs), c(Rank.three, Suit.clubs)]),
        player(1, 'P2', [c(Rank.two, Suit.diamonds), c(Rank.three, Suit.diamonds)]),
        player(2, 'P3', [c(Rank.two, Suit.hearts), c(Rank.three, Suit.hearts)]),
      ];

      final community = [
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.spades),
        c(Rank.jack, Suit.clubs),
        c(Rank.ten, Suit.diamonds),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: community,
        gameType: GameType.texasHoldem,
      );

      // Each player should get ~33.3% equity.
      expect(result.playerEquities.length, 3);
      for (final eq in result.playerEquities) {
        expect(eq.equity, closeTo(1.0 / 3, 0.01));
      }
      final total = result.playerEquities
          .map((e) => e.equity)
          .reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 0.01));
    });

    test('flop equity — partial board', () {
      final players = [
        player(0, 'Hero', [c(Rank.ace, Suit.spades), c(Rank.ace, Suit.hearts)]),
        player(1, 'Villain', [c(Rank.king, Suit.spades), c(Rank.king, Suit.hearts)]),
      ];

      final community = [
        c(Rank.two, Suit.clubs),
        c(Rank.seven, Suit.diamonds),
        c(Rank.ten, Suit.spades),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: community,
        gameType: GameType.texasHoldem,
        simulations: 3000,
        seed: 42,
      );

      // AA is ahead on this board — should have high equity.
      expect(result[0]!.equity, greaterThan(0.85));
    });

    test('three-way pot equity sums to 1.0', () {
      final players = [
        player(0, 'P1', [c(Rank.ace, Suit.spades), c(Rank.king, Suit.spades)]),
        player(1, 'P2', [c(Rank.queen, Suit.hearts), c(Rank.jack, Suit.hearts)]),
        player(2, 'P3', [c(Rank.eight, Suit.clubs), c(Rank.eight, Suit.diamonds)]),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 3000,
        seed: 42,
      );

      expect(result.playerEquities.length, 3);

      final totalEquity = result.playerEquities
          .map((e) => e.equity)
          .reduce((a, b) => a + b);
      expect(totalEquity, closeTo(1.0, 0.02));
    });

    test('Omaha equity calculation works', () {
      final players = [
        player(0, 'Hero', [
          c(Rank.ace, Suit.spades),
          c(Rank.ace, Suit.hearts),
          c(Rank.king, Suit.spades),
          c(Rank.king, Suit.hearts),
        ]),
        player(1, 'Villain', [
          c(Rank.two, Suit.clubs),
          c(Rank.three, Suit.clubs),
          c(Rank.four, Suit.diamonds),
          c(Rank.five, Suit.diamonds),
        ]),
      ];

      final result = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.omaha,
        simulations: 2000,
        seed: 42,
      );

      expect(result.playerEquities.length, 2);
      final total = result[0]!.equity + result[1]!.equity;
      expect(total, closeTo(1.0, 0.02));
    });

    test('equityPercent rounds correctly', () {
      const eq = PlayerEquity(
        playerIndex: 0,
        winRate: 0.754,
        tieRate: 0.02,
        simulations: 1000,
      );
      // equity = 0.754 + 0.01 = 0.764 => 76%
      expect(eq.equityPercent, 76);
    });

    test('empty players returns empty result', () {
      final result = EquityCalculator.calculate(
        players: [],
        communityCards: [],
        gameType: GameType.texasHoldem,
      );

      expect(result.playerEquities, isEmpty);
      expect(result.totalSimulations, 0);
    });

    test('seed produces deterministic results', () {
      final players = [
        player(0, 'P1', [c(Rank.ace, Suit.spades), c(Rank.king, Suit.spades)]),
        player(1, 'P2', [c(Rank.queen, Suit.hearts), c(Rank.jack, Suit.hearts)]),
      ];

      final result1 = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 1000,
        seed: 123,
      );

      final result2 = EquityCalculator.calculate(
        players: players,
        communityCards: [],
        gameType: GameType.texasHoldem,
        simulations: 1000,
        seed: 123,
      );

      expect(result1[0]!.winRate, result2[0]!.winRate);
      expect(result1[1]!.winRate, result2[1]!.winRate);
    });
  });
}
