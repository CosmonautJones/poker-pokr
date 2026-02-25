import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/providers/hand_setup_provider.dart';
import 'package:poker_trainer/poker/models/card.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  HandSetup readState() => container.read(handSetupProvider);
  HandSetupNotifier readNotifier() =>
      container.read(handSetupProvider.notifier);

  group('HandSetupNotifier', () {
    group('initial state', () {
      test('defaults to 6 players', () {
        expect(readState().playerCount, 6);
      });

      test('defaults to 1/2 blinds', () {
        expect(readState().smallBlind, 1);
        expect(readState().bigBlind, 2);
      });

      test('no ante by default', () {
        expect(readState().ante, 0);
      });

      test('dealer at seat 0', () {
        expect(readState().dealerIndex, 0);
      });

      test('200 chip stacks (100 BB)', () {
        for (final stack in readState().stacks) {
          expect(stack, 200);
        }
      });
    });

    group('setPlayerCount', () {
      test('changes player count', () {
        readNotifier().setPlayerCount(4);
        expect(readState().playerCount, 4);
      });

      test('adjusts name and stack lists to match new count', () {
        readNotifier().setPlayerCount(3);
        expect(readState().playerNames.length, 3);
        expect(readState().stacks.length, 3);
      });

      test('preserves existing names when shrinking', () {
        readNotifier().setPlayerName(0, 'Alice');
        readNotifier().setPlayerName(1, 'Bob');
        readNotifier().setPlayerCount(3);
        expect(readState().playerNames[0], 'Alice');
        expect(readState().playerNames[1], 'Bob');
      });

      test('adds default names when growing', () {
        readNotifier().setPlayerCount(3);
        readNotifier().setPlayerCount(5);
        expect(readState().playerNames[3], 'Player 4');
        expect(readState().playerNames[4], 'Player 5');
      });

      test('clamps dealer index if exceeds new count', () {
        readNotifier().setDealerIndex(5);
        readNotifier().setPlayerCount(3);
        expect(readState().dealerIndex, 0);
      });

      test('preserves dealer index if still valid', () {
        readNotifier().setDealerIndex(2);
        readNotifier().setPlayerCount(4);
        expect(readState().dealerIndex, 2);
      });

      test('adjusts hole cards list', () {
        readNotifier().dealRandomHoleCards(0);
        readNotifier().setPlayerCount(3);
        expect(readState().holeCards, isNotNull);
        expect(readState().holeCards!.length, 3);
        // Player 0's cards should be preserved.
        expect(readState().holeCards![0], isNotNull);
      });
    });

    group('blind setters', () {
      test('setSmallBlind', () {
        readNotifier().setSmallBlind(5);
        expect(readState().smallBlind, 5);
      });

      test('setBigBlind', () {
        readNotifier().setBigBlind(10);
        expect(readState().bigBlind, 10);
      });

      test('setAnte', () {
        readNotifier().setAnte(0.5);
        expect(readState().ante, 0.5);
      });
    });

    group('setDealerIndex', () {
      test('sets dealer to a specific seat', () {
        readNotifier().setDealerIndex(3);
        expect(readState().dealerIndex, 3);
      });
    });

    group('setPlayerName', () {
      test('changes a specific player name', () {
        readNotifier().setPlayerName(2, 'Charlie');
        expect(readState().playerNames[2], 'Charlie');
      });

      test('does not affect other names', () {
        final originalName = readState().playerNames[0];
        readNotifier().setPlayerName(2, 'Charlie');
        expect(readState().playerNames[0], originalName);
      });
    });

    group('setPlayerStack', () {
      test('changes a specific player stack', () {
        readNotifier().setPlayerStack(1, 500);
        expect(readState().stacks[1], 500);
      });

      test('does not affect other stacks', () {
        readNotifier().setPlayerStack(1, 500);
        expect(readState().stacks[0], 200);
      });
    });

    group('hole card management', () {
      test('setPlayerHoleCard assigns a card', () {
        final card = PokerCard.from(Rank.ace, Suit.spades);
        readNotifier().setPlayerHoleCard(0, 0, card);
        expect(readState().holeCards, isNotNull);
        expect(readState().holeCards![0], isNotNull);
        expect(readState().holeCards![0]![0].rank, Rank.ace);
        expect(readState().holeCards![0]![0].suit, Suit.spades);
      });

      test('can set both hole cards', () {
        final card1 = PokerCard.from(Rank.ace, Suit.spades);
        final card2 = PokerCard.from(Rank.king, Suit.spades);
        readNotifier().setPlayerHoleCard(0, 0, card1);
        readNotifier().setPlayerHoleCard(0, 1, card2);
        expect(readState().holeCards![0]!.length, 2);
        expect(readState().holeCards![0]![1].rank, Rank.king);
      });

      test('clearPlayerHoleCard removes a card', () {
        final card1 = PokerCard.from(Rank.ace, Suit.spades);
        final card2 = PokerCard.from(Rank.king, Suit.spades);
        readNotifier().setPlayerHoleCard(0, 0, card1);
        readNotifier().setPlayerHoleCard(0, 1, card2);
        readNotifier().clearPlayerHoleCard(0, 0);
        // After removing index 0, king should be at index 0.
        expect(readState().holeCards![0]!.length, 1);
        expect(readState().holeCards![0]![0].rank, Rank.king);
      });

      test('clearPlayerHoleCards removes all cards', () {
        readNotifier().dealRandomHoleCards(0);
        expect(readState().holeCards![0], isNotNull);
        readNotifier().clearPlayerHoleCards(0);
        expect(readState().holeCards![0], isNull);
      });

      test('clearPlayerHoleCard is no-op for non-existent card', () {
        readNotifier().clearPlayerHoleCard(0, 0);
        // Should not crash.
      });
    });

    group('dealRandomHoleCards', () {
      test('assigns 2 cards to the player', () {
        readNotifier().dealRandomHoleCards(0);
        expect(readState().holeCards![0], isNotNull);
        expect(readState().holeCards![0]!.length, 2);
      });

      test('dealt cards have valid values (0-51)', () {
        readNotifier().dealRandomHoleCards(0);
        for (final card in readState().holeCards![0]!) {
          expect(card.value, inInclusiveRange(0, 51));
        }
      });

      test('two cards for same player are different', () {
        readNotifier().dealRandomHoleCards(0);
        final cards = readState().holeCards![0]!;
        expect(cards[0].value, isNot(cards[1].value));
      });

      test('does not duplicate cards across players', () {
        readNotifier().dealRandomHoleCards(0);
        readNotifier().dealRandomHoleCards(1);
        final cards0 = readState().holeCards![0]!;
        final cards1 = readState().holeCards![1]!;
        final allValues = [...cards0, ...cards1].map((c) => c.value).toSet();
        expect(allValues.length, 4); // All unique.
      });

      test('avoids cards already assigned to other players', () {
        // Assign specific cards to player 0.
        final card1 = PokerCard.from(Rank.ace, Suit.spades);
        final card2 = PokerCard.from(Rank.king, Suit.spades);
        readNotifier().setPlayerHoleCard(0, 0, card1);
        readNotifier().setPlayerHoleCard(0, 1, card2);

        // Deal random cards to player 1.
        readNotifier().dealRandomHoleCards(1);
        final dealtCards = readState().holeCards![1]!;
        expect(dealtCards[0].value, isNot(card1.value));
        expect(dealtCards[0].value, isNot(card2.value));
        expect(dealtCards[1].value, isNot(card1.value));
        expect(dealtCards[1].value, isNot(card2.value));
      });
    });

    group('usedCardValues', () {
      test('returns empty set when no cards assigned', () {
        expect(readNotifier().usedCardValues(), isEmpty);
      });

      test('returns assigned card values', () {
        readNotifier().dealRandomHoleCards(0);
        readNotifier().dealRandomHoleCards(1);
        final used = readNotifier().usedCardValues();
        expect(used.length, 4);
      });

      test('excludes specified player', () {
        readNotifier().dealRandomHoleCards(0);
        readNotifier().dealRandomHoleCards(1);
        final usedExcluding0 = readNotifier().usedCardValues(0);
        // Should only have player 1's cards (2 cards).
        expect(usedExcluding0.length, 2);
      });
    });
  });

  group('activeHandSetupProvider', () {
    test('starts as null', () {
      expect(container.read(activeHandSetupProvider), isNull);
    });

    test('can be set to a HandSetup', () {
      final setup = HandSetup.defaults();
      container.read(activeHandSetupProvider.notifier).state = setup;
      expect(container.read(activeHandSetupProvider), isNotNull);
      expect(container.read(activeHandSetupProvider)!.playerCount, 6);
    });
  });
}
