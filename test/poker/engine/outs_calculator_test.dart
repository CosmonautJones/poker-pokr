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
    test('flush draw on flop has 9 outs', () {
      // Hole: Ah Kh, Board: 2h 7h 9c -> 4 hearts, need 1 more = 9 outs
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ah'), _card('Kh')],
        communityCards: [_card('2h'), _card('7h'), _card('9c')],
        gameType: GameType.texasHoldem,
      );
      // 9 hearts remain in the deck (13 - 4 used).
      // But we also get outs from pairing A or K, so outs >= 9.
      // The flush draw alone accounts for 9 cards.
      expect(result.outs, greaterThanOrEqualTo(9));
      expect(result.drawTypes, contains('flush draw'));
    });

    test('open-ended straight draw has at least 8 outs', () {
      // Hole: 8c 9d, Board: 7h Ts 2c -> need 6 or J for straight = 8 outs
      final result = OutsCalculator.calculate(
        holeCards: [_card('8c'), _card('9d')],
        communityCards: [_card('7h'), _card('Ts'), _card('2c')],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, greaterThanOrEqualTo(8));
      expect(result.drawTypes, contains('open-ended straight draw'));
    });

    test('gutshot straight draw has at least 4 outs', () {
      // Hole: 8c 9d, Board: 6h Ts 2c -> need 7 for straight = 4 outs (gutshot)
      final result = OutsCalculator.calculate(
        holeCards: [_card('8c'), _card('9d')],
        communityCards: [_card('6h'), _card('Ts'), _card('2c')],
        gameType: GameType.texasHoldem,
      );
      expect(result.outs, greaterThanOrEqualTo(4));
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
      // Hole: Ks Kd, Board: Kh 5c 9s -> trips, can improve to quads/full house
      final result = OutsCalculator.calculate(
        holeCards: [_card('Ks'), _card('Kd')],
        communityCards: [_card('Kh'), _card('5c'), _card('9s')],
        gameType: GameType.texasHoldem,
      );
      // At least 1 out (last King for quads), plus cards that pair the board
      // for a full house.
      expect(result.outs, greaterThan(0));
    });
  });
}
