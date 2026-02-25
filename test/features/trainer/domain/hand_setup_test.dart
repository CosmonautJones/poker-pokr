import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/models/card.dart';

void main() {
  group('HandSetup', () {
    group('defaults factory', () {
      test('creates 6-player game by default', () {
        final setup = HandSetup.defaults();
        expect(setup.playerCount, 6);
      });

      test('sets standard blind structure', () {
        final setup = HandSetup.defaults();
        expect(setup.smallBlind, 1);
        expect(setup.bigBlind, 2);
        expect(setup.ante, 0);
      });

      test('dealer is at seat 0', () {
        final setup = HandSetup.defaults();
        expect(setup.dealerIndex, 0);
      });

      test('generates correct number of player names', () {
        final setup = HandSetup.defaults(playerCount: 4);
        expect(setup.playerNames.length, 4);
        expect(setup.playerNames[0], 'Player 1');
        expect(setup.playerNames[3], 'Player 4');
      });

      test('all stacks are 100 big blinds', () {
        final setup = HandSetup.defaults(playerCount: 3);
        expect(setup.stacks.length, 3);
        for (final stack in setup.stacks) {
          expect(stack, 200); // 100 * 2 (BB)
        }
      });

      test('holeCards is null by default', () {
        final setup = HandSetup.defaults();
        expect(setup.holeCards, isNull);
      });

      test('accepts custom player count', () {
        final setup = HandSetup.defaults(playerCount: 9);
        expect(setup.playerCount, 9);
        expect(setup.playerNames.length, 9);
        expect(setup.stacks.length, 9);
      });
    });

    group('copyWith', () {
      test('creates a copy with changed values', () {
        final setup = HandSetup.defaults();
        final modified = setup.copyWith(
          playerCount: 3,
          smallBlind: 5,
          bigBlind: 10,
        );
        expect(modified.playerCount, 3);
        expect(modified.smallBlind, 5);
        expect(modified.bigBlind, 10);
        // Unchanged fields stay the same.
        expect(modified.ante, setup.ante);
        expect(modified.dealerIndex, setup.dealerIndex);
      });

      test('returns same values when no arguments are given', () {
        final setup = HandSetup.defaults();
        final copy = setup.copyWith();
        expect(copy.playerCount, setup.playerCount);
        expect(copy.smallBlind, setup.smallBlind);
        expect(copy.bigBlind, setup.bigBlind);
      });

      test('can set hole cards', () {
        final setup = HandSetup.defaults(playerCount: 2);
        final holeCards = [
          [PokerCard.from(Rank.ace, Suit.spades), PokerCard.from(Rank.king, Suit.spades)],
          [PokerCard.from(Rank.queen, Suit.hearts), PokerCard.from(Rank.jack, Suit.hearts)],
        ];
        final modified = setup.copyWith(holeCards: holeCards);
        expect(modified.holeCards, isNotNull);
        expect(modified.holeCards!.length, 2);
        expect(modified.holeCards![0]![0].rank, Rank.ace);
      });
    });
  });
}
