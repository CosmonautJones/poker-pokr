import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/poker/models/street.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';

void main() {
  group('GameEngine.createInitialState', () {
    group('6-player game', () {
      late GameState state;

      setUp(() {
        state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );
      });

      test('creates 6 players', () {
        expect(state.players.length, 6);
      });

      test('dealer is at index 0', () {
        expect(state.dealerIndex, 0);
      });

      test('SB is dealer+1 (index 1)', () {
        // SB player should have currentBet of 1
        expect(state.players[1].currentBet, 1);
        expect(state.players[1].stack, 199); // 200 - 1 = 199
      });

      test('BB is dealer+2 (index 2)', () {
        // BB player should have currentBet of 2
        expect(state.players[2].currentBet, 2);
        expect(state.players[2].stack, 200 - 2); // 200 - 2 = 198
      });

      test('first to act is UTG (dealer+3 = index 3)', () {
        expect(state.currentPlayerIndex, 3);
      });

      test('current bet is BB', () {
        expect(state.currentBet, 2);
      });

      test('pot equals SB + BB', () {
        expect(state.pot, 3); // 1 + 2
      });

      test('street is preflop', () {
        expect(state.street, Street.preflop);
      });

      test('hand is not complete', () {
        expect(state.isHandComplete, false);
      });

      test('default stacks are 100 * BB', () {
        // Non-blind players should have full starting stack
        expect(state.players[0].stack, 200); // dealer, no blind
        expect(state.players[3].stack, 200); // UTG, no blind
      });

      test('non-blind players have zero currentBet', () {
        expect(state.players[0].currentBet, 0);
        expect(state.players[3].currentBet, 0);
        expect(state.players[4].currentBet, 0);
        expect(state.players[5].currentBet, 0);
      });
    });

    group('2-player heads-up', () {
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

      test('dealer posts SB', () {
        // In heads-up, dealer (index 0) posts SB
        expect(state.players[0].currentBet, 1);
      });

      test('other player posts BB', () {
        expect(state.players[1].currentBet, 2);
      });

      test('dealer acts first preflop', () {
        expect(state.currentPlayerIndex, 0);
      });

      test('pot is SB + BB', () {
        expect(state.pot, 3);
      });
    });

    group('hole cards', () {
      test('each player gets 2 hole cards', () {
        final state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        for (final player in state.players) {
          expect(player.holeCards.length, 2,
              reason: '${player.name} should have 2 hole cards');
        }
      });

      test('all dealt hole cards are unique', () {
        final state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final allCards = <int>{};
        for (final player in state.players) {
          for (final card in player.holeCards) {
            expect(allCards.add(card.value), true,
                reason: 'Duplicate card found: $card');
          }
        }
        expect(allCards.length, 12); // 6 players * 2 cards
      });

      test('pre-assigned hole cards are used', () {
        final holeCards = [
          [PokerCard.from(Rank.ace, Suit.spades), PokerCard.from(Rank.ace, Suit.hearts)],
          [PokerCard.from(Rank.king, Suit.spades), PokerCard.from(Rank.king, Suit.hearts)],
        ];

        final state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          holeCards: holeCards,
          deckSeed: 42,
        );

        expect(state.players[0].holeCards[0], PokerCard.from(Rank.ace, Suit.spades));
        expect(state.players[0].holeCards[1], PokerCard.from(Rank.ace, Suit.hearts));
        expect(state.players[1].holeCards[0], PokerCard.from(Rank.king, Suit.spades));
        expect(state.players[1].holeCards[1], PokerCard.from(Rank.king, Suit.hearts));
      });
    });

    group('ante posting', () {
      test('antes are deducted from all stacks', () {
        final state = GameEngine.createInitialState(
          playerCount: 4,
          smallBlind: 1,
          bigBlind: 2,
          ante: 0.5,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Dealer (0): ante only -> 200 - 0.5 = 199.5
        expect(state.players[0].stack, 199.5);
        // SB (1): ante + SB -> 200 - 0.5 - 1 = 198.5
        expect(state.players[1].stack, 198.5);
        // BB (2): ante + BB -> 200 - 0.5 - 2 = 197.5
        expect(state.players[2].stack, 197.5);
        // Player 3: ante only -> 200 - 0.5 = 199.5
        expect(state.players[3].stack, 199.5);
      });

      test('pot includes all antes and blinds', () {
        final state = GameEngine.createInitialState(
          playerCount: 4,
          smallBlind: 1,
          bigBlind: 2,
          ante: 0.5,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // 4 antes (0.5 each) + SB(1) + BB(2) = 2 + 1 + 2 = 5
        expect(state.pot, 5);
      });

      test('totalInvested tracks antes and blinds', () {
        final state = GameEngine.createInitialState(
          playerCount: 4,
          smallBlind: 1,
          bigBlind: 2,
          ante: 0.5,
          dealerIndex: 0,
          deckSeed: 42,
        );

        expect(state.players[0].totalInvested, 0.5); // ante only
        expect(state.players[1].totalInvested, 1.5); // ante + SB
        expect(state.players[2].totalInvested, 2.5); // ante + BB
        expect(state.players[3].totalInvested, 0.5); // ante only
      });
    });

    group('custom names and stacks', () {
      test('custom names are applied', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          names: ['Alice', 'Bob', 'Charlie'],
          deckSeed: 42,
        );

        expect(state.players[0].name, 'Alice');
        expect(state.players[1].name, 'Bob');
        expect(state.players[2].name, 'Charlie');
      });

      test('custom stacks are applied', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          stacks: [100, 50, 200],
          deckSeed: 42,
        );

        // Dealer (0): 100 (no blind)
        expect(state.players[0].stack, 100);
        // SB (1): 50 - 1 = 49
        expect(state.players[1].stack, 49);
        // BB (2): 200 - 2 = 198
        expect(state.players[2].stack, 198);
      });
    });
  });

  group('GameEngine.applyAction', () {
    group('fold', () {
      test('reduces active player count', () {
        final state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final activeBefore =
            state.players.where((p) => !p.isFolded).length;

        final newState = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: state.currentPlayerIndex,
            type: ActionType.fold,
          ),
        );

        final activeAfter =
            newState.players.where((p) => !p.isFolded).length;
        expect(activeAfter, activeBefore - 1);
      });

      test('marks the folding player as folded', () {
        final state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final foldingPlayer = state.currentPlayerIndex;
        final newState = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: foldingPlayer,
            type: ActionType.fold,
          ),
        );

        expect(newState.players[foldingPlayer].isFolded, true);
      });
    });

    group('check', () {
      test('advances to next player on flop', () {
        // Get to flop in a heads-up game, then check once
        var state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Dealer (SB) calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );
        // BB checks -> advance to flop
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.check),
        );

        expect(state.street, Street.flop);
        // Postflop: first active after dealer = player 1
        expect(state.currentPlayerIndex, 1);

        // Player 1 checks -> should advance to player 0
        final newState = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.check),
        );

        expect(newState.currentPlayerIndex, 0);
        expect(newState.street, Street.flop); // still on flop
      });

      test('BB check preflop ends betting round and advances street', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );
        // SB calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.call),
        );
        // BB checks -> preflop complete, advance to flop
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 2, type: ActionType.check),
        );

        expect(state.street, Street.flop);
      });
    });

    group('call', () {
      test('matches current bet', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG (player 0) calls the BB of 2
        final newState = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );

        expect(newState.players[0].currentBet, 2);
        expect(newState.players[0].stack, 200 - 2);
      });

      test('increases pot by call amount', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final potBefore = state.pot;
        final newState = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );

        expect(newState.pot, potBefore + 2); // called 2
      });
    });

    group('bet', () {
      test('sets current bet and increases pot', () {
        // Need a postflop scenario where no bet exists
        // Create a 3-player game and get to flop
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );
        // SB calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.call),
        );
        // BB checks
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 2, type: ActionType.check),
        );

        // Now on flop. Pot should be 6 (3*2). currentBet = 0.
        expect(state.street, Street.flop);
        expect(state.currentBet, 0);

        final potBefore = state.pot;
        final currentPlayer = state.currentPlayerIndex;

        // First active player after dealer bets
        state = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: currentPlayer,
            type: ActionType.bet,
            amount: 4,
          ),
        );

        expect(state.currentBet, 4);
        expect(state.pot, potBefore + 4);
      });
    });

    group('raise', () {
      test('increases current bet', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG raises to 6 (min raise is to 4, so 6 is legal)
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.raise, amount: 6),
        );

        expect(state.currentBet, 6);
        expect(state.players[0].currentBet, 6);
        expect(state.players[0].stack, 200 - 6);
      });

      test('pot increases by the additional chips', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final potBefore = state.pot; // 3 (SB+BB)
        // UTG raises to 6 (puts in 6 chips since currentBet is 0 for UTG)
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.raise, amount: 6),
        );

        expect(state.pot, potBefore + 6);
      });
    });

    group('all-in', () {
      test('sets player all-in flag and stack to zero', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final playerIndex = state.currentPlayerIndex; // UTG = 0
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: playerIndex, type: ActionType.allIn),
        );

        expect(state.players[playerIndex].isAllIn, true);
        expect(state.players[playerIndex].stack, 0);
      });

      test('moves entire stack into pot', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final playerIndex = state.currentPlayerIndex;
        final stackBefore = state.players[playerIndex].stack;
        final potBefore = state.pot;

        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: playerIndex, type: ActionType.allIn),
        );

        expect(state.pot, potBefore + stackBefore);
      });
    });

    group('error cases', () {
      test('throws if hand is complete', () {
        // Create a game and fold everyone except one
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG folds
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.fold),
        );
        // SB folds -> hand complete, BB wins
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.fold),
        );

        expect(state.isHandComplete, true);

        expect(
          () => GameEngine.applyAction(
            state,
            PokerAction(playerIndex: 2, type: ActionType.fold),
          ),
          throwsStateError,
        );
      });

      test('throws if wrong player acts', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Current player is UTG (index 0), try to act as player 1
        expect(
          () => GameEngine.applyAction(
            state,
            PokerAction(playerIndex: 1, type: ActionType.fold),
          ),
          throwsStateError,
        );
      });
    });
  });

  group('Full hand scenarios', () {
    test('everyone folds to BB preflop - BB wins', () {
      var state = GameEngine.createInitialState(
        playerCount: 4,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );
      // Dealer=0, SB=1, BB=2, UTG=3
      // First to act = 3 (UTG)

      // UTG folds
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 3, type: ActionType.fold),
      );
      // Dealer folds
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 0, type: ActionType.fold),
      );
      // SB folds
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 1, type: ActionType.fold),
      );

      expect(state.isHandComplete, true);
      // BB (index 2) should be the only player left
      final inHand = state.players.where((p) => !p.isFolded).toList();
      expect(inHand.length, 1);
      expect(inHand.first.index, 2);
      expect(state.winnerIndices, contains(2));
    });

    test('preflop raise, call, flop check-check, turn bet-fold', () {
      var state = GameEngine.createInitialState(
        playerCount: 2,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );
      // Heads-up: dealer=0 posts SB, player 1 posts BB
      // Dealer acts first preflop

      // Dealer raises to 6
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 0, type: ActionType.raise, amount: 6),
      );

      // BB calls
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 1, type: ActionType.call),
      );

      // Should be on flop now
      expect(state.street, Street.flop);
      expect(state.communityCards.length, 3);

      // Postflop: first active after dealer. In HU, that's player 1
      // Player 1 checks
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );

      // Dealer checks
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );

      // Should be on turn
      expect(state.street, Street.turn);
      expect(state.communityCards.length, 4);

      // Player 1 bets
      state = GameEngine.applyAction(
        state,
        PokerAction(
          playerIndex: state.currentPlayerIndex,
          type: ActionType.bet,
          amount: 4,
        ),
      );

      // Dealer folds
      state = GameEngine.applyAction(
        state,
        PokerAction(
          playerIndex: state.currentPlayerIndex,
          type: ActionType.fold,
        ),
      );

      expect(state.isHandComplete, true);
      // Player 1 wins
      final inHand = state.players.where((p) => !p.isFolded).toList();
      expect(inHand.length, 1);
      expect(inHand.first.index, 1);
    });

    test('all players check through all streets to showdown', () {
      var state = GameEngine.createInitialState(
        playerCount: 2,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );

      // Preflop: dealer (SB) calls (matches BB)
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      // BB checks
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 1, type: ActionType.check),
      );
      expect(state.street, Street.flop);
      expect(state.communityCards.length, 3);

      // Flop: both check
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );
      expect(state.street, Street.turn);
      expect(state.communityCards.length, 4);

      // Turn: both check
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );
      expect(state.street, Street.river);
      expect(state.communityCards.length, 5);

      // River: both check -> showdown
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: state.currentPlayerIndex, type: ActionType.check),
      );

      expect(state.isHandComplete, true);
      expect(state.communityCards.length, 5);
      // Both players should be in the winner candidates (showdown)
      expect(state.winnerIndices, containsAll([0, 1]));
    });

    test('action history records all actions', () {
      var state = GameEngine.createInitialState(
        playerCount: 3,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );

      // UTG calls
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      // SB folds
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 1, type: ActionType.fold),
      );
      // BB checks
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 2, type: ActionType.check),
      );

      expect(state.actionHistory.length, 3);
      expect(state.actionHistory[0].type, ActionType.call);
      expect(state.actionHistory[1].type, ActionType.fold);
      expect(state.actionHistory[2].type, ActionType.check);
    });
  });
}
