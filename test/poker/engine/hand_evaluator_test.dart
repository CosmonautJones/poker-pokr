import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/hand_evaluator.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/player.dart';

PokerCard c(Rank rank, Suit suit) => PokerCard.from(rank, suit);

void main() {
  group('HandEvaluator.evaluate5', () {
    test('high card', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.two, Suit.clubs),
        c(Rank.five, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.nine, Suit.spades),
        c(Rank.king, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.highCard);
      expect(hand.description, 'King High');
    });

    test('pair', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.pair);
      expect(hand.description, 'Pair of Kings');
    });

    test('two pair', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.seven, Suit.spades),
        c(Rank.ace, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.twoPair);
      expect(hand.description, 'Two Pair, Kings and Sevens');
    });

    test('three of a kind', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.queen, Suit.clubs),
        c(Rank.queen, Suit.diamonds),
        c(Rank.queen, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.threeOfAKind);
      expect(hand.description, 'Three of a Kind, Queens');
    });

    test('straight (normal)', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.five, Suit.clubs),
        c(Rank.six, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.eight, Suit.spades),
        c(Rank.nine, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.straight);
      expect(hand.description, 'Straight, Nine high');
    });

    test('straight (ace-low wheel)', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.ace, Suit.clubs),
        c(Rank.two, Suit.diamonds),
        c(Rank.three, Suit.hearts),
        c(Rank.four, Suit.spades),
        c(Rank.five, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.straight);
      expect(hand.description, 'Straight, Five high');
      // Wheel should rank lower than a 6-high straight.
      expect(hand.values, [5]);
    });

    test('straight (ace-high broadway)', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.ten, Suit.clubs),
        c(Rank.jack, Suit.diamonds),
        c(Rank.queen, Suit.hearts),
        c(Rank.king, Suit.spades),
        c(Rank.ace, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.straight);
      expect(hand.description, 'Straight, Ace high');
    });

    test('flush', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.two, Suit.hearts),
        c(Rank.five, Suit.hearts),
        c(Rank.seven, Suit.hearts),
        c(Rank.nine, Suit.hearts),
        c(Rank.king, Suit.hearts),
      ]);
      expect(hand.rank, HandRank.flush);
      expect(hand.description, 'Flush, King high');
    });

    test('full house', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.jack, Suit.clubs),
        c(Rank.jack, Suit.diamonds),
        c(Rank.jack, Suit.hearts),
        c(Rank.four, Suit.spades),
        c(Rank.four, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.fullHouse);
      expect(hand.description, 'Jacks full of Fours');
    });

    test('four of a kind', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.ace, Suit.clubs),
        c(Rank.ace, Suit.diamonds),
        c(Rank.ace, Suit.hearts),
        c(Rank.ace, Suit.spades),
        c(Rank.king, Suit.clubs),
      ]);
      expect(hand.rank, HandRank.fourOfAKind);
      expect(hand.description, 'Four of a Kind, Aces');
    });

    test('straight flush', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.five, Suit.spades),
        c(Rank.six, Suit.spades),
        c(Rank.seven, Suit.spades),
        c(Rank.eight, Suit.spades),
        c(Rank.nine, Suit.spades),
      ]);
      expect(hand.rank, HandRank.straightFlush);
      expect(hand.description, 'Straight Flush, Nine high');
    });

    test('royal flush', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.ten, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.queen, Suit.hearts),
        c(Rank.king, Suit.hearts),
        c(Rank.ace, Suit.hearts),
      ]);
      expect(hand.rank, HandRank.straightFlush);
      expect(hand.description, 'Royal Flush');
    });

    test('ace-low straight flush', () {
      final hand = HandEvaluator.evaluate5([
        c(Rank.ace, Suit.diamonds),
        c(Rank.two, Suit.diamonds),
        c(Rank.three, Suit.diamonds),
        c(Rank.four, Suit.diamonds),
        c(Rank.five, Suit.diamonds),
      ]);
      expect(hand.rank, HandRank.straightFlush);
      expect(hand.values, [5]); // 5-high, not ace-high
    });
  });

  group('Hand ranking comparison', () {
    test('flush beats straight', () {
      final flush = HandEvaluator.evaluate5([
        c(Rank.two, Suit.hearts),
        c(Rank.five, Suit.hearts),
        c(Rank.seven, Suit.hearts),
        c(Rank.nine, Suit.hearts),
        c(Rank.king, Suit.hearts),
      ]);
      final straight = HandEvaluator.evaluate5([
        c(Rank.five, Suit.clubs),
        c(Rank.six, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.eight, Suit.spades),
        c(Rank.nine, Suit.clubs),
      ]);
      expect(flush > straight, true);
    });

    test('higher pair beats lower pair', () {
      final pairKings = HandEvaluator.evaluate5([
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      final pairQueens = HandEvaluator.evaluate5([
        c(Rank.queen, Suit.clubs),
        c(Rank.queen, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      expect(pairKings > pairQueens, true);
    });

    test('pair with higher kicker wins', () {
      final pairWithAce = HandEvaluator.evaluate5([
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
        c(Rank.ace, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      final pairWithQueen = HandEvaluator.evaluate5([
        c(Rank.king, Suit.hearts),
        c(Rank.king, Suit.spades),
        c(Rank.queen, Suit.hearts),
        c(Rank.three, Suit.clubs),
        c(Rank.two, Suit.diamonds),
      ]);
      expect(pairWithAce > pairWithQueen, true);
    });

    test('identical hands are equal', () {
      final hand1 = HandEvaluator.evaluate5([
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.diamonds),
        c(Rank.seven, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      final hand2 = HandEvaluator.evaluate5([
        c(Rank.king, Suit.hearts),
        c(Rank.king, Suit.spades),
        c(Rank.seven, Suit.clubs),
        c(Rank.three, Suit.diamonds),
        c(Rank.two, Suit.hearts),
      ]);
      expect(hand1.compareTo(hand2), 0);
    });

    test('full house beats flush', () {
      final fullHouse = HandEvaluator.evaluate5([
        c(Rank.three, Suit.clubs),
        c(Rank.three, Suit.diamonds),
        c(Rank.three, Suit.hearts),
        c(Rank.two, Suit.spades),
        c(Rank.two, Suit.clubs),
      ]);
      final flush = HandEvaluator.evaluate5([
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.nine, Suit.hearts),
      ]);
      expect(fullHouse > flush, true);
    });

    test('wheel (A-5 straight) loses to 6-high straight', () {
      final wheel = HandEvaluator.evaluate5([
        c(Rank.ace, Suit.clubs),
        c(Rank.two, Suit.diamonds),
        c(Rank.three, Suit.hearts),
        c(Rank.four, Suit.spades),
        c(Rank.five, Suit.clubs),
      ]);
      final sixHigh = HandEvaluator.evaluate5([
        c(Rank.two, Suit.hearts),
        c(Rank.three, Suit.spades),
        c(Rank.four, Suit.clubs),
        c(Rank.five, Suit.diamonds),
        c(Rank.six, Suit.hearts),
      ]);
      expect(sixHigh > wheel, true);
    });
  });

  group('Best hand from 7 cards', () {
    test('selects flush from 7 cards', () {
      final holeCards = [
        c(Rank.ace, Suit.hearts),
        c(Rank.two, Suit.hearts),
      ];
      final community = [
        c(Rank.five, Suit.hearts),
        c(Rank.eight, Suit.hearts),
        c(Rank.king, Suit.clubs),
        c(Rank.jack, Suit.hearts),
        c(Rank.three, Suit.spades),
      ];
      final best = HandEvaluator.evaluateBestHand(holeCards, community);
      expect(best.rank, HandRank.flush);
    });

    test('selects full house over flush', () {
      final holeCards = [
        c(Rank.king, Suit.clubs),
        c(Rank.king, Suit.hearts),
      ];
      final community = [
        c(Rank.king, Suit.diamonds),
        c(Rank.five, Suit.hearts),
        c(Rank.five, Suit.diamonds),
        c(Rank.two, Suit.hearts),
        c(Rank.seven, Suit.hearts),
      ];
      final best = HandEvaluator.evaluateBestHand(holeCards, community);
      expect(best.rank, HandRank.fullHouse);
      expect(best.description, 'Kings full of Fives');
    });
  });

  group('determineWinners', () {
    test('pair beats high card', () {
      final players = [
        PlayerState(
          index: 0,
          name: 'Alice',
          stack: 100,
          holeCards: [c(Rank.ace, Suit.spades), c(Rank.king, Suit.spades)],
        ),
        PlayerState(
          index: 1,
          name: 'Bob',
          stack: 100,
          holeCards: [c(Rank.ten, Suit.clubs), c(Rank.ten, Suit.diamonds)],
        ),
      ];
      final community = [
        c(Rank.two, Suit.hearts),
        c(Rank.five, Suit.clubs),
        c(Rank.seven, Suit.diamonds),
        c(Rank.nine, Suit.spades),
        c(Rank.three, Suit.hearts),
      ];

      final winners =
          HandEvaluator.determineWinners(players, community, [0, 1]);
      // Bob has a pair of 10s; Alice has AK high.
      expect(winners, [1]);
    });

    test('split pot with identical hands', () {
      final players = [
        PlayerState(
          index: 0,
          name: 'Alice',
          stack: 100,
          holeCards: [c(Rank.two, Suit.clubs), c(Rank.three, Suit.clubs)],
        ),
        PlayerState(
          index: 1,
          name: 'Bob',
          stack: 100,
          holeCards: [c(Rank.two, Suit.diamonds), c(Rank.three, Suit.diamonds)],
        ),
      ];
      // Board makes the best 5-card hand for both players.
      final community = [
        c(Rank.ace, Suit.hearts),
        c(Rank.king, Suit.hearts),
        c(Rank.queen, Suit.hearts),
        c(Rank.jack, Suit.hearts),
        c(Rank.ten, Suit.hearts),
      ];

      final winners =
          HandEvaluator.determineWinners(players, community, [0, 1]);
      // Both have the same royal flush on the board.
      expect(winners.length, 2);
      expect(winners, containsAll([0, 1]));
    });
  });
}
