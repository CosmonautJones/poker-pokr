import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';

void main() {
  group('LegalActionSet.compute', () {
    group('preflop UTG in 6-player game', () {
      late GameState state;
      late LegalActionSet legal;

      setUp(() {
        state = GameEngine.createInitialState(
          playerCount: 6,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );
        // UTG is at index 3 (dealer+3)
        expect(state.currentPlayerIndex, 3);
        legal = LegalActionSet.compute(state);
      });

      test('can fold (facing BB)', () {
        expect(legal.canFold, true);
      });

      test('cannot check (facing BB)', () {
        expect(legal.canCheck, false);
      });

      test('has call option equal to BB', () {
        expect(legal.callAmount, isNotNull);
        expect(legal.callAmount, 2); // must call the BB of 2
      });

      test('has raise range', () {
        expect(legal.raiseRange, isNotNull);
        // Min raise = currentBet + lastRaiseSize = 2 + 2 = 4
        expect(legal.raiseRange!.min, 4);
        // Max raise = playerBet + stack = 0 + 200 = 200
        expect(legal.raiseRange!.max, 200);
      });

      test('can go all-in', () {
        expect(legal.canAllIn, true);
        expect(legal.allInAmount, 200);
      });
    });

    group('BB when no raise (just calls)', () {
      late GameState state;
      late LegalActionSet legal;

      setUp(() {
        // 3-player: dealer=0, SB=1, BB=2, first to act=0 (UTG)
        state = GameEngine.createInitialState(
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

        // Now it's BB's turn (index 2), everyone has just called
        expect(state.currentPlayerIndex, 2);
        legal = LegalActionSet.compute(state);
      });

      test('can check', () {
        expect(legal.canCheck, true);
      });

      test('cannot fold (checking is free, canFold is false)', () {
        expect(legal.canFold, false);
      });

      test('no call needed (already matched)', () {
        expect(legal.callAmount, isNull);
      });

      test('has bet range (opening bet since no additional bet)', () {
        // BB's currentBet == currentBet, so facingBet is false
        // betRange min = BB = 2, max = stack
        expect(legal.betRange, isNotNull);
        expect(legal.betRange!.min, 2);
      });

      test('can go all-in', () {
        expect(legal.canAllIn, true);
      });
    });

    group('facing a bet on flop', () {
      late GameState state;
      late LegalActionSet legal;

      setUp(() {
        // Create a 2-player game, get to flop, then one player bets
        state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Dealer calls (SB calls to match BB)
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );
        // BB checks
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.check),
        );

        // Flop. First active player after dealer = player 1
        expect(state.street, Street.flop);

        // Player 1 bets 4
        state = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: state.currentPlayerIndex,
            type: ActionType.bet,
            amount: 4,
          ),
        );

        // Now player 0 faces a bet
        legal = LegalActionSet.compute(state);
      });

      test('can fold', () {
        expect(legal.canFold, true);
      });

      test('cannot check', () {
        expect(legal.canCheck, false);
      });

      test('can call the bet', () {
        expect(legal.callAmount, isNotNull);
        expect(legal.callAmount, 4);
      });

      test('can raise', () {
        expect(legal.raiseRange, isNotNull);
        // Min raise = currentBet + lastRaise = 4 + 4 = 8
        expect(legal.raiseRange!.min, 8);
      });

      test('can go all-in', () {
        expect(legal.canAllIn, true);
      });
    });

    group('player has less than call amount (short stack)', () {
      late GameState state;
      late LegalActionSet legal;

      setUp(() {
        // Create a game where one player has a tiny stack
        state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          stacks: [200, 200, 200],
          deckSeed: 42,
        );

        // UTG raises to 50
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.raise, amount: 50),
        );

        // SB (index 1) raises to 150
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.raise, amount: 150),
        );

        // BB (index 2) faces 150, has 198 stack (200 - 2 BB)
        // toCall = 150 - 2 = 148. stack = 198.
        // That's enough to call. Let's make a scenario with a truly short stack.
        // Let's restart with custom stacks.
        state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          stacks: [200, 200, 5],
          deckSeed: 42,
        );

        // UTG raises to 10
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.raise, amount: 10),
        );

        // SB calls
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.call),
        );

        // BB (index 2) has stack = 5 - 2 (BB) = 3. Faces 10.
        // toCall = 10 - 2 = 8. stack = 3. Cannot fully call.
        expect(state.currentPlayerIndex, 2);
        legal = LegalActionSet.compute(state);
      });

      test('can fold', () {
        expect(legal.canFold, true);
      });

      test('call amount is capped at remaining stack', () {
        // callAmount = min(toCall, stack) = min(8, 3) = 3
        expect(legal.callAmount, 3);
      });

      test('cannot raise (not enough chips)', () {
        // stack (3) <= toCall (8), so no raise range
        expect(legal.raiseRange, isNull);
      });

      test('can go all-in', () {
        expect(legal.canAllIn, true);
        expect(legal.allInAmount, 3);
      });
    });

    group('minimum raise sizing', () {
      test('min raise preflop is at least BB (raise to currentBet + BB)', () {
        final state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        final legal = LegalActionSet.compute(state);
        // Min raise to = currentBet + lastRaiseSize = 2 + 2 = 4
        expect(legal.raiseRange, isNotNull);
        expect(legal.raiseRange!.min, 4);
      });

      test('min raise after a raise is previous raise plus current bet', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // UTG raises to 6 (raise size = 6 - 2 = 4)
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.raise, amount: 6),
        );

        // SB faces raise to 6
        final legal = LegalActionSet.compute(state);
        // Min raise = currentBet + lastRaiseSize = 6 + 4 = 10
        expect(legal.raiseRange, isNotNull);
        expect(legal.raiseRange!.min, 10);
      });

      test('min bet on flop is BB', () {
        var state = GameEngine.createInitialState(
          playerCount: 2,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Get to flop
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.call),
        );
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.check),
        );

        expect(state.street, Street.flop);
        final legal = LegalActionSet.compute(state);
        expect(legal.betRange, isNotNull);
        expect(legal.betRange!.min, 2); // BB = 2
      });
    });

    group('hand complete returns empty actions', () {
      test('no actions available when hand is complete', () {
        var state = GameEngine.createInitialState(
          playerCount: 3,
          smallBlind: 1,
          bigBlind: 2,
          dealerIndex: 0,
          deckSeed: 42,
        );

        // Everyone folds to BB
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 0, type: ActionType.fold),
        );
        state = GameEngine.applyAction(
          state,
          PokerAction(playerIndex: 1, type: ActionType.fold),
        );

        expect(state.isHandComplete, true);
        final legal = LegalActionSet.compute(state);

        expect(legal.canFold, false);
        expect(legal.canCheck, false);
        expect(legal.callAmount, isNull);
        expect(legal.betRange, isNull);
        expect(legal.raiseRange, isNull);
        expect(legal.canAllIn, false);
      });
    });
  });
}
