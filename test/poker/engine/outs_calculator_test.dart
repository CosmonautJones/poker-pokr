import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/outs_calculator.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Helper to create a card from a short string like "Ah" (Ace of hearts).
PokerCard _card(String s) {
  final rankChar = s.substring(0, s.length - 1);
  final suitChar = s[s.length - 1];

  final rank = switch (rankChar) {
    '2' => Rank.two,
    '3' => Rank.three,
    '4' => Rank.four,
    '5' => Rank.five,
    '6' => Rank.six,
    '7' => Rank.seven,
    '8' => Rank.eight,
    '9' => Rank.nine,
    '10' || 'T' => Rank.ten,
    'J' => Rank.jack,
    'Q' => Rank.queen,
    'K' => Rank.king,
    'A' => Rank.ace,
    _ => throw ArgumentError('Unknown rank: $rankChar'),
  };

  final suit = switch (suitChar) {
    'c' => Suit.clubs,
    'd' => Suit.diamonds,
    'h' => Suit.hearts,
    's' => Suit.spades,
    _ => throw ArgumentError('Unknown suit: $suitChar'),
  };

  return PokerCard(suit.index * 13 + rank.index);
}

void main() {
  group('OutsCalculator', () {
    test('flush draw on flop counts all improving cards', () {
      // Hole: Ah Kh, Board: 2h 7h 9c -> 4 hearts, need 1 more.
      // 9 remaining hearts complete the flush.
      // 3 remaining Aces and 3 remaining Kings pair the hole cards.
      // Total outs: 9 (flush) + 6 (pair) = 15.
      // But cards that do both (Ah/Kh already in hand) are not double-counted,
      // and we must check which pairs actually IMPROVE the hand (they do — pair
      // beats high card). So outs = 15.
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [_card('2h'), _card('7h'), _card('9c')],
        gameType: GameType.texasHoldem,
      );
      // 9 flush outs + 6 pair outs = 15
      expect(result.outs, 15);
      expect(result.drawTypes, contains('flush draw'));
    });

    test('open-ended straight draw counts correctly', () {
      // Hole: 8c 9d, Board: 7h Ts 2c -> need 6 or J for straight.
      // 4 sixes + 4 jacks = 8 straight outs.
      // Additionally: pairing 8 or 9 improves high card to a pair = 6 more outs.
      // Total = 14.
      final result = OutsCalculator.calculate(
        holeCards: [_card('8c'), _card('9d')],
        communityCards: [_card('7h'), _card('Ts'), _card('2c')],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, 14);
      expect(result.drawTypes, contains('open-ended straight draw'));
    });

    test('gutshot straight draw counts correctly', () {
      // Hole: 8c 9d, Board: 6h Ts 2c -> need 7 for straight = 4 outs.
      // Also pairing 8 or 9 improves the hand = 6 more outs.
      // Total = 10.
      final result = OutsCalculator.calculate(
        holeCards: [_card('8c'), _card('9d')],
        communityCards: [_card('6h'), _card('Ts'), _card('2c')],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, 10);
      expect(result.drawTypes, contains('gutshot straight draw'));
    });

    test('river returns 0 outs', () {
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [
          _card('2h'),
          _card('7c'),
          _card('9c'),
          _card('Ts'),
          _card('3d'),
        ],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, 0);
    });

    test('preflop returns 0 outs', () {
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, 0);
    });

    test('overcards detected', () {
      // Hole: Ah Kd, Board: 5c 7h 9s -> both overcards
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kd')],
        communityCards: [_card('5c'), _card('7h'), _card('9s')],
        gameType: GameType.texasHoldem,
      );
      expect(result.drawTypes, contains('two overcards'));
    });

    test('rough equity uses rule of 4 on flop', () {
      // Flop with some outs -> equity = outs * 4
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [_card('2h'), _card('7h'), _card('9c')],
        gameType: GameType.texasHoldem,
      );
      expect(result.roughEquityPercent, result.outs * 4);
    });

    test('rough equity uses rule of 2 on turn', () {
      // Turn with flush draw -> equity = outs * 2
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [_card('2h'), _card('7h'), _card('9c'), _card('3d')],
        gameType: GameType.texasHoldem,
      );
      expect(result.roughEquityPercent, result.outs * 2);
    });

    test('made hand still counts improving outs', () {
      // Hole: Ks Kd, Board: Kh 5c 9s -> trips, can improve to quads/full house.
      // 1 remaining King = quads.
      // 3 remaining fives + 3 remaining nines = 6 cards for full house.
      // Total improving outs = 7.
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ks'), _card('Kd')],
        communityCards: [_card('Kh'), _card('5c'), _card('9s')],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, 7);
    });

    test('Omaha outs use exactly 2 hole + 3 community rule', () {
      // Omaha: 4 hole cards, must use exactly 2.
      // Hole: Ah Kh Qs Jd, Board: 2h 7h 9c
      // Flush draw using Ah+Kh with 2h 7h = 4 hearts, need 1 more.
      // But in Omaha, best hand must use exactly 2 hole cards, so the
      // evaluation is different from Hold'em.
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh'), _card('Qs'), _card('Jd')],
        communityCards: [_card('2h'), _card('7h'), _card('9c')],
        gameType: GameType.omaha,
      );
      // Should have outs (flush draw is present with Ah+Kh combo).
      expect(result.outs, greaterThan(0));
      expect(result.drawTypes, contains('flush draw'));
    });
  });
}
