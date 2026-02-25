import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:poker_trainer/poker/models/street.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';

void main() {
  // ===========================================================================
  // 6-player game with straddle (2x BB)
  // ===========================================================================
  group('6-player game with straddle', () {
    // Dealer=0, SB=1, BB=2, Straddle(UTG)=3, seats 4 & 5 after straddler.
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 6,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        straddle: 4,
        deckSeed: 42,
      );
    });

    test('straddle player is seat 3 (UTG)', () {
      expect(state.straddlePlayerIndex, 3);
    });

    test('straddle amount deducted from straddler stack', () {
      expect(state.players[3].currentBet, 4);
      expect(state.players[3].stack, 196); // 200 - 4
    });

    test('pot includes SB + BB + straddle', () {
      // SB(1) + BB(2) + straddle(4) = 7
      expect(state.pot, 7);
    });

    test('current bet equals straddle amount', () {
      expect(state.currentBet, 4);
    });

    test('last raise size is straddle minus bigBlind', () {
      // The increment from BB (2) to straddle (4) is 2.
      expect(state.lastRaiseSize, 2);
    });

    test('first to act is seat 4 (player after straddler)', () {
      expect(state.currentPlayerIndex, 4);
    });

    test('straddler gets option (can check when action wraps back)', () {
      // All players call the straddle of 4.
      // Action order: 4, 5, 0 (dealer), 1 (SB), 2 (BB), then 3 (straddler).
      var s = state;

      // Seat 4 calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 4, type: ActionType.call),
      );
      // Seat 5 calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 5, type: ActionType.call),
      );
      // Seat 0 (dealer) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      // Seat 1 (SB) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 1, type: ActionType.call),
      );
      // Seat 2 (BB) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 2, type: ActionType.call),
      );

      // It should now be the straddler's (seat 3) turn — the "option".
      expect(s.street, Street.preflop);
      expect(s.currentPlayerIndex, 3);
    });

    test('game state records straddle info', () {
      expect(state.straddle, 4);
      expect(state.straddlePlayerIndex, 3);
    });
  });

  // ===========================================================================
  // 6-player game with 5x straddle
  // ===========================================================================
  group('6-player game with 5x straddle', () {
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 6,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        straddle: 10,
        deckSeed: 42,
      );
    });

    test('pot includes SB + BB + straddle of 10', () {
      // SB(1) + BB(2) + straddle(10) = 13
      expect(state.pot, 13);
    });

    test('current bet is 10', () {
      expect(state.currentBet, 10);
    });

    test('last raise size is 8', () {
      // 10 (straddle) - 2 (BB) = 8
      expect(state.lastRaiseSize, 8);
    });
  });

  // ===========================================================================
  // Straddle ignored heads-up
  // ===========================================================================
  group('Straddle ignored heads-up', () {
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 2,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        straddle: 4,
        deckSeed: 42,
      );
    });

    test('no straddle in heads-up', () {
      expect(state.straddlePlayerIndex, isNull);
      expect(state.straddle, 0);
    });

    test('pot is just SB + BB', () {
      // SB(1) + BB(2) = 3
      expect(state.pot, 3);
    });
  });

  // ===========================================================================
  // Straddle player with short stack
  // ===========================================================================
  group('Straddle player with short stack', () {
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 6,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        straddle: 4,
        stacks: [200, 200, 200, 3, 200, 200],
        deckSeed: 42,
      );
    });

    test('straddler goes all-in for less than straddle', () {
      expect(state.players[3].isAllIn, true);
      expect(state.players[3].currentBet, 3);
    });

    test('pot reflects actual amount posted', () {
      // SB(1) + BB(2) + straddler all-in(3) = 6
      expect(state.pot, 6);
    });
  });

  // ===========================================================================
  // Straddler option with full action
  // ===========================================================================
  group('Straddler option with full action', () {
    late GameState state;

    setUp(() {
      state = GameEngine.createInitialState(
        playerCount: 6,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        straddle: 4,
        deckSeed: 42,
      );
    });

    test('after all calls, it is the straddler turn (seat 3)', () {
      var s = state;

      // Seat 4 calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 4, type: ActionType.call),
      );
      // Seat 5 calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 5, type: ActionType.call),
      );
      // Seat 0 (dealer) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      // Seat 1 (SB) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 1, type: ActionType.call),
      );
      // Seat 2 (BB) calls
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 2, type: ActionType.call),
      );

      // Straddler (seat 3) should get the option.
      expect(s.currentPlayerIndex, 3);
      expect(s.street, Street.preflop);
    });

    test('legal actions include check (not just call)', () {
      var s = state;

      // Everyone calls around to the straddler.
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 4, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 5, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 1, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 2, type: ActionType.call),
      );

      // Verify straddler's legal actions.
      final legal = LegalActionSet.compute(s);
      expect(legal.canCheck, true);
      // Should not need to call — already matched the bet.
      expect(legal.callAmount, isNull);
    });

    test('straddler can also raise', () {
      var s = state;

      // Everyone calls around to the straddler.
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 4, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 5, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 0, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 1, type: ActionType.call),
      );
      s = GameEngine.applyAction(
        s,
        PokerAction(playerIndex: 2, type: ActionType.call),
      );

      // The straddler has the option — they can raise.
      final legal = LegalActionSet.compute(s);

      // Since the straddler's current bet matches currentBet (both 4),
      // there is no facing bet, so a "raise" is actually a bet from the
      // legal-actions perspective (opening bet when currentBet == playerBet).
      // The key point is the straddler can put more money in.
      expect(legal.betRange, isNotNull);
      expect(legal.canAllIn, true);
    });
  });
}
