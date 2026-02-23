import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/poker/models/street.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/street_progression.dart';

void main() {
  /// Helper: creates a standard 3-player game and navigates through preflop.
  GameState _preflopComplete3Player() {
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
    return state;
  }

  group('StreetProgression.isBettingRoundComplete', () {
    test('not complete before all players have acted', () {
      final state = GameEngine.createInitialState(
        playerCount: 3,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );

      // No one has acted yet
      expect(StreetProgression.isBettingRoundComplete(state), false);
    });

    test('complete after all active players have acted and bets matched', () {
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

      // Now BB needs to act. After SB call, isBettingRoundComplete should be false
      // because BB hasn't acted yet.
      expect(StreetProgression.isBettingRoundComplete(state), false);

      // BB checks -> round complete
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 2, type: ActionType.check),
      );
      // After BB checks, the engine should have already advanced to flop
      expect(state.street, Street.flop);
    });

    test('complete when only one active non-all-in player remains', () {
      // Create a scenario where one player is all-in and others folded except one
      final players = [
        PlayerState(index: 0, name: 'P0', stack: 0, currentBet: 100, totalInvested: 100, isAllIn: true),
        PlayerState(index: 1, name: 'P1', stack: 100, currentBet: 100, totalInvested: 100),
        PlayerState(index: 2, name: 'P2', stack: 80, totalInvested: 20, isFolded: true),
      ];

      final state = GameState(
        players: players,
        deck: Deck(seed: 1),
        street: Street.flop,
        pot: 220,
        currentPlayerIndex: 1,
        currentBet: 100,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        playersActedThisStreet: 2,
      );

      // Only P1 is active non-all-in, so betting round should be complete
      expect(StreetProgression.isBettingRoundComplete(state), true);
    });
  });

  group('StreetProgression.advanceStreet', () {
    test('flop deals 3 community cards', () {
      final state = _preflopComplete3Player();
      expect(state.street, Street.flop);
      expect(state.communityCards.length, 3);
    });

    test('turn deals 1 card (total 4)', () {
      var state = _preflopComplete3Player();

      // Flop: all check
      final p1 = state.currentPlayerIndex;
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: p1, type: ActionType.check),
      );
      final p2 = state.currentPlayerIndex;
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: p2, type: ActionType.check),
      );
      final p3 = state.currentPlayerIndex;
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: p3, type: ActionType.check),
      );

      expect(state.street, Street.turn);
      expect(state.communityCards.length, 4);
    });

    test('river deals 1 card (total 5)', () {
      var state = _preflopComplete3Player();

      // Check through flop and turn
      for (int street = 0; street < 2; street++) {
        for (int i = 0; i < 3; i++) {
          state = GameEngine.applyAction(
            state,
            PokerAction(
              playerIndex: state.currentPlayerIndex,
              type: ActionType.check,
            ),
          );
        }
      }

      expect(state.street, Street.river);
      expect(state.communityCards.length, 5);
    });

    test('resets currentBet to 0 on new street', () {
      final state = _preflopComplete3Player();
      expect(state.currentBet, 0);
    });

    test('resets player currentBets to 0 on new street', () {
      final state = _preflopComplete3Player();
      for (final player in state.players) {
        expect(player.currentBet, 0,
            reason: '${player.name} currentBet should be 0 on new street');
      }
    });

    test('resets playersActedThisStreet to 0 on new street', () {
      final state = _preflopComplete3Player();
      expect(state.playersActedThisStreet, 0);
    });

    test('community cards are unique', () {
      var state = _preflopComplete3Player();

      // Check through flop, turn, river
      for (int street = 0; street < 3; street++) {
        for (int i = 0; i < 3; i++) {
          if (state.isHandComplete) break;
          state = GameEngine.applyAction(
            state,
            PokerAction(
              playerIndex: state.currentPlayerIndex,
              type: ActionType.check,
            ),
          );
        }
      }

      final values = state.communityCards.map((c) => c.value).toSet();
      expect(values.length, state.communityCards.length);
    });
  });

  group('StreetProgression.isHandComplete', () {
    test('hand complete when one player remains after folds', () {
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
      // SB folds -> only BB remains
      state = GameEngine.applyAction(
        state,
        PokerAction(playerIndex: 1, type: ActionType.fold),
      );

      expect(state.isHandComplete, true);
    });

    test('hand not complete mid-street with active players', () {
      final state = GameEngine.createInitialState(
        playerCount: 3,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 42,
      );

      expect(state.isHandComplete, false);
    });
  });

  group('StreetProgression.shouldRunOutBoard', () {
    test('true when all remaining players are all-in', () {
      final players = [
        PlayerState(index: 0, name: 'P0', stack: 0, totalInvested: 100, isAllIn: true),
        PlayerState(index: 1, name: 'P1', stack: 0, totalInvested: 100, isAllIn: true),
        PlayerState(index: 2, name: 'P2', stack: 80, totalInvested: 20, isFolded: true),
      ];

      final state = GameState(
        players: players,
        deck: Deck(seed: 1),
        street: Street.flop,
        pot: 220,
        currentPlayerIndex: 0,
        currentBet: 100,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
      );

      expect(StreetProgression.shouldRunOutBoard(state), true);
    });

    test('true when only one non-all-in player remains', () {
      final players = [
        PlayerState(index: 0, name: 'P0', stack: 0, totalInvested: 50, isAllIn: true),
        PlayerState(index: 1, name: 'P1', stack: 100, totalInvested: 50),
        PlayerState(index: 2, name: 'P2', stack: 80, totalInvested: 20, isFolded: true),
      ];

      final state = GameState(
        players: players,
        deck: Deck(seed: 1),
        street: Street.flop,
        pot: 120,
        currentPlayerIndex: 1,
        currentBet: 50,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
      );

      expect(StreetProgression.shouldRunOutBoard(state), true);
    });

    test('false when multiple non-all-in players remain', () {
      final players = [
        PlayerState(index: 0, name: 'P0', stack: 100, totalInvested: 50),
        PlayerState(index: 1, name: 'P1', stack: 100, totalInvested: 50),
      ];

      final state = GameState(
        players: players,
        deck: Deck(seed: 1),
        street: Street.flop,
        pot: 100,
        currentPlayerIndex: 0,
        currentBet: 50,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
      );

      expect(StreetProgression.shouldRunOutBoard(state), false);
    });
  });

  group('Street enum', () {
    test('next street progression', () {
      expect(Street.preflop.next, Street.flop);
      expect(Street.flop.next, Street.turn);
      expect(Street.turn.next, Street.river);
      expect(Street.river.next, Street.showdown);
      expect(Street.showdown.next, Street.showdown);
    });

    test('showdown is terminal', () {
      expect(Street.showdown.isTerminal, true);
      expect(Street.preflop.isTerminal, false);
      expect(Street.river.isTerminal, false);
    });
  });
}
