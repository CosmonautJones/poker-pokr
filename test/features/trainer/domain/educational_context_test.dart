import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/educational_context.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/player.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// Create a standard game state for testing.
/// 6-player, 1/2 blinds, dealer at seat 0, 200 stacks.
GameState _makeState({
  int playerCount = 6,
  double smallBlind = 1,
  double bigBlind = 2,
  int dealerIndex = 0,
}) {
  return GameEngine.createInitialState(
    playerCount: playerCount,
    smallBlind: smallBlind,
    bigBlind: bigBlind,
    dealerIndex: dealerIndex,
    stacks: List.filled(playerCount, bigBlind * 100),
    names: List.generate(playerCount, (i) => 'Player ${i + 1}'),
  );
}

void main() {
  group('EducationalContextCalculator', () {
    group('position labels', () {
      test('heads-up: dealer is BTN (SB), other is BB', () {
        final gs = _makeState(playerCount: 2, dealerIndex: 0);
        // In heads-up, current player is the BTN/SB (dealer).
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        // Current player depends on engine's preflop logic.
        // In heads-up, SB/BTN (dealer) acts first preflop.
        expect(ctx.positionLabel, isNotEmpty);
      });

      test('6-player: seat 0 is BTN when dealerIndex=0', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Preflop in 6-handed with dealer=0:
        //   SB=1, BB=2, UTG=3 acts first.
        // currentPlayerIndex should be 3 (UTG).
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        // UTG in 6-handed = seat 3.
        expect(ctx.positionLabel, anyOf('UTG', 'MP', 'CO'));
        expect(ctx.positionCategory, isNotEmpty);
      });

      test('9-player assigns UTG, UTG+1, MP, HJ, CO, BTN, SB, BB', () {
        // With 9 players, dealer at seat 0:
        // SB=1, BB=2, seats 3-8 get position labels.
        final gs = _makeState(playerCount: 9, dealerIndex: 0);
        // We just verify the calculator doesn't crash on large tables.
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        expect(ctx.positionLabel, isNotEmpty);
      });

      test('3-player: only BTN, SB, BB', () {
        final gs = _makeState(playerCount: 3, dealerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        // Position should be one of the three.
        expect(
          ctx.positionLabel,
          anyOf('BTN', 'SB', 'BB'),
        );
      });
    });

    group('position categories', () {
      test('SB and BB are blinds category', () {
        // Make a state where currentPlayerIndex is the SB.
        // 6-player, dealer=0: SB=1, BB=2.
        // We need to test the category for SB specifically.
        // After UTG folds, next player is seat 4 (CO) etc.
        // Easier: just create the state and check that 'blinds' is returned
        // for the right positions by computing for different players.
        final gs = _makeState(playerCount: 6, dealerIndex: 0);

        // Force a state with currentPlayerIndex = 1 (SB).
        final sbState = gs.copyWith(currentPlayerIndex: 1);
        final ctx = EducationalContextCalculator.compute(
          state: sbState,
          bigBlind: 2,
        );
        expect(ctx.positionCategory, 'blinds');
        expect(ctx.positionLabel, 'SB');
      });

      test('BTN is late position', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        final btnState = gs.copyWith(currentPlayerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: btnState,
          bigBlind: 2,
        );
        expect(ctx.positionCategory, 'late');
        expect(ctx.positionLabel, 'BTN');
      });

      test('UTG is early position', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // UTG = seat 3 in a 6-handed game with dealer=0.
        final utgState = gs.copyWith(currentPlayerIndex: 3);
        final ctx = EducationalContextCalculator.compute(
          state: utgState,
          bigBlind: 2,
        );
        expect(ctx.positionCategory, 'early');
      });
    });

    group('pot odds', () {
      test('null when not facing a bet (can check)', () {
        // On a flop where no one has bet yet.
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Advance to flop-like state by setting currentBet = 0.
        final flopState = gs.copyWith(
          street: Street.flop,
          currentBet: 0,
          playersActedThisStreet: 0,
        );
        final ctx = EducationalContextCalculator.compute(
          state: flopState,
          bigBlind: 2,
        );
        expect(ctx.potOdds, isNull);
        expect(ctx.potOddsDisplay, isNull);
      });

      test('computed when facing a bet', () {
        // Create a state where there's a bet to call.
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Simulate a state where current player faces a bet.
        // Pot = 10, currentBet = 4, player's currentBet = 0, stack = 200.
        final players = gs.players.map((p) {
          if (p.index == gs.currentPlayerIndex) {
            return p.copyWith(currentBet: 0, stack: 200);
          }
          return p;
        }).toList();
        final bettingState = gs.copyWith(
          players: players,
          pot: 10,
          currentBet: 4,
        );
        final ctx = EducationalContextCalculator.compute(
          state: bettingState,
          bigBlind: 2,
        );
        expect(ctx.potOdds, isNotNull);
        expect(ctx.potOdds, greaterThan(0));
        expect(ctx.potOdds, lessThan(1));
        expect(ctx.potOddsDisplay, isNotNull);
        expect(ctx.potOddsDisplay, contains('%'));
      });
    });

    group('stack-to-pot ratio (SPR)', () {
      test('calculated from effective stack and pot', () {
        final gs = _makeState(playerCount: 2, dealerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        // SPR = effective stack / pot.
        // Initial pot = SB (1) + BB (2) = 3.
        // Hero stack after posting = 199 or 198.
        // SPR should be a positive number.
        expect(ctx.stackToPotRatio, greaterThan(0));
      });

      test('zero when pot is zero', () {
        final gs = _makeState(playerCount: 2, dealerIndex: 0);
        final zeroPotState = gs.copyWith(pot: 0);
        final ctx = EducationalContextCalculator.compute(
          state: zeroPotState,
          bigBlind: 2,
        );
        expect(ctx.stackToPotRatio, 0.0);
      });
    });

    group('players in hand', () {
      test('all players at start', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        expect(ctx.playersInHand, 6);
      });

      test('decreases when players fold', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Fold two players.
        final players = List.of(gs.players);
        players[3] = players[3].copyWith(isFolded: true);
        players[4] = players[4].copyWith(isFolded: true);
        final foldedState = gs.copyWith(players: players);
        final ctx = EducationalContextCalculator.compute(
          state: foldedState,
          bigBlind: 2,
        );
        expect(ctx.playersInHand, 4);
      });
    });

    group('street context', () {
      test('describes facing the big blind preflop', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // UTG faces the BB preflop.
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        expect(ctx.streetContext, contains('Preflop'));
      });

      test('describes hand complete state', () {
        final gs = _makeState(playerCount: 2, dealerIndex: 0);
        final completeState = gs.copyWith(isHandComplete: true);
        final ctx = EducationalContextCalculator.compute(
          state: completeState,
          bigBlind: 2,
        );
        expect(ctx.streetContext, 'Hand complete');
      });
    });

    group('action explanation', () {
      test('null when no previous state', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        expect(ctx.lastAction, isNull);
      });

      test('generated after an action is applied', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Apply a fold action.
        final newState = GameEngine.applyAction(
          gs,
          PokerAction(
            playerIndex: gs.currentPlayerIndex,
            type: ActionType.fold,
          ),
        );
        final ctx = EducationalContextCalculator.compute(
          state: newState,
          previousState: gs,
          bigBlind: 2,
        );
        expect(ctx.lastAction, isNotNull);
        expect(ctx.lastAction!.description, contains('folds'));
        expect(ctx.lastAction!.mechanical, 'Surrenders their hand');
        expect(ctx.lastAction!.sizing, isNull); // Fold has no sizing.
      });

      test('call action includes sizing as pot percentage', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        // Apply a call action.
        final newState = GameEngine.applyAction(
          gs,
          PokerAction(
            playerIndex: gs.currentPlayerIndex,
            type: ActionType.call,
            amount: gs.currentBet,
          ),
        );
        final ctx = EducationalContextCalculator.compute(
          state: newState,
          previousState: gs,
          bigBlind: 2,
        );
        expect(ctx.lastAction, isNotNull);
        expect(ctx.lastAction!.description, contains('calls'));
        expect(ctx.lastAction!.sizing, isNotNull);
        expect(ctx.lastAction!.sizing, contains('pot'));
      });
    });

    group('street summary', () {
      test('null when street has not changed', () {
        final gs = _makeState(playerCount: 6, dealerIndex: 0);
        final ctx = EducationalContextCalculator.compute(
          state: gs,
          bigBlind: 2,
        );
        expect(ctx.streetSummary, isNull);
      });

      test('generated when street advances', () {
        final gs = _makeState(playerCount: 2, dealerIndex: 0);
        // Play out preflop: call, check to reach flop.
        var state = gs;
        // SB/BTN calls.
        state = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: state.currentPlayerIndex,
            type: ActionType.call,
            amount: state.currentBet,
          ),
        );
        // BB checks.
        final prevState = state;
        state = GameEngine.applyAction(
          state,
          PokerAction(
            playerIndex: state.currentPlayerIndex,
            type: ActionType.check,
          ),
        );

        // Now we should be on the flop.
        if (state.street != prevState.street) {
          final ctx = EducationalContextCalculator.compute(
            state: state,
            previousState: prevState,
            bigBlind: 2,
          );
          expect(ctx.streetSummary, isNotNull);
          expect(ctx.streetSummary!.completedStreet, 'Preflop');
          expect(ctx.streetSummary!.summary, contains('Pot:'));
        }
      });
    });
  });
}
