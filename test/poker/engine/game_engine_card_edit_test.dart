import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

void main() {
  group('GameEngine card editing', () {
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 2,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );
    });

    group('replaceHoleCards', () {
      test('replaces player hole cards', () {
        final newCards = [
          PokerCard.from(Rank.ace, Suit.spades),
          PokerCard.from(Rank.king, Suit.spades),
        ];
        final updated = GameEngine.replaceHoleCards(state, 0, newCards);

        expect(updated.players[0].holeCards, newCards);
        // Other player unchanged.
        expect(updated.players[1].holeCards, state.players[1].holeCards);
      });

      test('maintains deck consistency', () {
        final oldCards = state.players[0].holeCards;
        final newCards = [
          PokerCard.from(Rank.ace, Suit.spades),
          PokerCard.from(Rank.king, Suit.spades),
        ];

        final updated = GameEngine.replaceHoleCards(state, 0, newCards);

        // Old cards should be back in the deck.
        final deckValues = updated.deck.cards.map((c) => c.value).toSet();
        for (final card in oldCards) {
          expect(deckValues.contains(card.value), isTrue,
              reason: 'Old card ${card} should be in deck');
        }

        // New cards should NOT be in the deck.
        for (final card in newCards) {
          expect(deckValues.contains(card.value), isFalse,
              reason: 'New card ${card} should not be in deck');
        }
      });

      test('total card count is preserved', () {
        final totalBefore = state.deck.remaining +
            state.players.fold<int>(
                0, (sum, p) => sum + p.holeCards.length) +
            state.communityCards.length;

        final newCards = [
          PokerCard.from(Rank.ace, Suit.spades),
          PokerCard.from(Rank.king, Suit.spades),
        ];
        final updated = GameEngine.replaceHoleCards(state, 0, newCards);

        final totalAfter = updated.deck.remaining +
            updated.players.fold<int>(
                0, (sum, p) => sum + p.holeCards.length) +
            updated.communityCards.length;

        expect(totalAfter, totalBefore);
      });
    });

    group('replaceCommunityCards', () {
      test('replaces community cards', () {
        // First advance to flop by playing some actions.
        final stateWithCommunity = state.copyWith(
          communityCards: [
            PokerCard.from(Rank.two, Suit.hearts),
            PokerCard.from(Rank.three, Suit.hearts),
            PokerCard.from(Rank.four, Suit.hearts),
          ],
        );

        final newCommunity = [
          PokerCard.from(Rank.ace, Suit.hearts),
          PokerCard.from(Rank.king, Suit.hearts),
          PokerCard.from(Rank.queen, Suit.hearts),
        ];

        final updated =
            GameEngine.replaceCommunityCards(stateWithCommunity, newCommunity);

        expect(updated.communityCards, newCommunity);
      });

      test('maintains deck consistency with community swap', () {
        final oldCommunity = [
          PokerCard.from(Rank.two, Suit.hearts),
          PokerCard.from(Rank.three, Suit.hearts),
          PokerCard.from(Rank.four, Suit.hearts),
        ];

        final stateWithCommunity = state.copyWith(
          communityCards: oldCommunity,
        );

        final newCommunity = [
          PokerCard.from(Rank.ace, Suit.hearts),
          PokerCard.from(Rank.king, Suit.hearts),
          PokerCard.from(Rank.queen, Suit.hearts),
        ];

        final updated = GameEngine.replaceCommunityCards(
            stateWithCommunity, newCommunity);

        final deckValues = updated.deck.cards.map((c) => c.value).toSet();
        for (final card in oldCommunity) {
          expect(deckValues.contains(card.value), isTrue);
        }
        for (final card in newCommunity) {
          expect(deckValues.contains(card.value), isFalse);
        }
      });
    });
  });
}
