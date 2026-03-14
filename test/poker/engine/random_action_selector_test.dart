import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';
import 'package:poker_trainer/poker/engine/random_action_selector.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

void main() {
  group('RandomActionSelector', () {
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

    test('returns a legal action', () {
      final rng = Random(123);
      for (int i = 0; i < 50; i++) {
        final action = RandomActionSelector.selectAction(state, random: rng);
        expect(action.playerIndex, state.currentPlayerIndex);

        final legal = LegalActionSet.compute(state);
        // Verify the action type is legal.
        switch (action.type) {
          case ActionType.fold:
            expect(legal.canFold, isTrue);
          case ActionType.check:
            expect(legal.canCheck, isTrue);
          case ActionType.call:
            expect(legal.callAmount, isNotNull);
          case ActionType.bet:
            expect(legal.betRange, isNotNull);
            expect(action.amount, greaterThanOrEqualTo(legal.betRange!.min));
            expect(action.amount, lessThanOrEqualTo(legal.betRange!.max));
          case ActionType.raise:
            expect(legal.raiseRange, isNotNull);
            expect(action.amount, greaterThanOrEqualTo(legal.raiseRange!.min));
            expect(action.amount, lessThanOrEqualTo(legal.raiseRange!.max));
          case ActionType.allIn:
            expect(legal.canAllIn, isTrue);
        }
      }
    });

    test('can play a full hand without errors', () {
      final rng = Random(42);
      var current = state;

      for (int i = 0; i < 200; i++) {
        if (current.isHandComplete) break;
        final action =
            RandomActionSelector.selectAction(current, random: rng);
        current = GameEngine.applyAction(current, action);
      }

      // Hand should complete within 200 actions for a 6-player game.
      expect(current.isHandComplete, isTrue);
    });

    test('works with heads-up game', () {
      final headsUp = GameEngine.createInitialState(
        playerCount: 2,
        smallBlind: 1,
        bigBlind: 2,
        dealerIndex: 0,
        deckSeed: 99,
      );

      final rng = Random(77);
      var current = headsUp;
      for (int i = 0; i < 100; i++) {
        if (current.isHandComplete) break;
        final action =
            RandomActionSelector.selectAction(current, random: rng);
        current = GameEngine.applyAction(current, action);
      }

      expect(current.isHandComplete, isTrue);
    });

    test('deterministic with same seed', () {
      final action1 =
          RandomActionSelector.selectAction(state, random: Random(42));
      final action2 =
          RandomActionSelector.selectAction(state, random: Random(42));
      expect(action1, action2);
    });
  });
}
