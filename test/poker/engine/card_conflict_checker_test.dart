import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/card_conflict_checker.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/models/card.dart';

void main() {
  group('CardConflictChecker', () {
    group('usedCardValues', () {
      test('returns all hole cards and community cards', () {
        final state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final used = CardConflictChecker.usedCardValues(state);
        // 2 players x 2 hole cards = 4 cards, no community cards yet
        expect(used.length, 4);
      });

      test('excludes specified player', () {
        final state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final usedExclude0 =
            CardConflictChecker.usedCardValues(state, excludePlayerIndex: 0);
        // Only player 1's 2 hole cards
        expect(usedExclude0.length, 2);

        final usedAll = CardConflictChecker.usedCardValues(state);
        expect(usedAll.length, 4);
      });
    });

    group('findConflicts', () {
      test('returns empty for valid state', () {
        final state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        expect(CardConflictChecker.findConflicts(state), isEmpty);
      });

      test('detects duplicate hole cards', () {
        // Manually create a state with conflicting cards.
        final card = PokerCard.from(Rank.ace, Suit.spades);
        final state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          holeCards: [
            [card, PokerCard.from(Rank.king, Suit.spades)],
            [card, PokerCard.from(Rank.queen, Suit.spades)],
          ],
        );

        final conflicts = CardConflictChecker.findConflicts(state);
        expect(conflicts, contains(card.value));
      });
    });
  });
}
