import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/data/mappers/hand_mapper.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/player.dart';

// Builds a minimal valid GameState for use in actionsToCompanions tests.
GameState _minimalState() => GameState(
      players: [
        PlayerState(index: 0, name: 'Player 1', stack: 200),
        PlayerState(index: 1, name: 'Player 2', stack: 200),
      ],
      deck: Deck(seed: 1),
      smallBlind: 1,
      bigBlind: 2,
      dealerIndex: 0,
    );

void main() {
  group('HandMapper.setupToCompanion', () {
    test('throws ArgumentError when playerNames.length != playerCount', () {
      // playerCount is 4 but only 3 names are provided.
      final setup = HandSetup(
        playerCount: 4,
        smallBlind: 1,
        bigBlind: 2,
        playerNames: ['Alice', 'Bob', 'Carol'], // length 3, not 4
        stacks: [200.0, 200.0, 200.0, 200.0],
      );
      expect(
        () => HandMapper.setupToCompanion(setup),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when stacks.length != playerCount', () {
      // playerCount is 4 but only 2 stacks are provided.
      final setup = HandSetup(
        playerCount: 4,
        smallBlind: 1,
        bigBlind: 2,
        playerNames: ['Alice', 'Bob', 'Carol', 'Dave'],
        stacks: [200.0, 200.0], // length 2, not 4
      );
      expect(
        () => HandMapper.setupToCompanion(setup),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('succeeds when lengths all match playerCount', () {
      final setup = HandSetup.defaults(playerCount: 4);
      // Should not throw.
      expect(() => HandMapper.setupToCompanion(setup), returnsNormally);
    });
  });

  group('HandMapper.actionsToCompanions', () {
    test('throws ArgumentError when states.length != actions.length + 1', () {
      final actions = [
        const PokerAction(playerIndex: 0, type: ActionType.call),
        const PokerAction(playerIndex: 1, type: ActionType.fold),
      ];
      // Provide 2 states instead of the required 3 (actions.length + 1).
      final states = [_minimalState(), _minimalState()];

      expect(
        () => HandMapper.actionsToCompanions(1, actions, states),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError when states is empty but actions is non-empty',
        () {
      final actions = [
        const PokerAction(playerIndex: 0, type: ActionType.check),
      ];
      // Zero states provided, but we need 2 (actions.length + 1).
      expect(
        () => HandMapper.actionsToCompanions(1, actions, []),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('succeeds with matching lengths (1 action, 2 states)', () {
      final actions = [
        const PokerAction(playerIndex: 0, type: ActionType.call),
      ];
      final states = [_minimalState(), _minimalState()];

      final companions =
          HandMapper.actionsToCompanions(42, actions, states);
      expect(companions.length, 1);
    });

    test('succeeds with empty actions and single state', () {
      final companions =
          HandMapper.actionsToCompanions(1, [], [_minimalState()]);
      expect(companions, isEmpty);
    });

    test('succeeds with multiple actions and states.length == actions.length + 1',
        () {
      final actions = [
        const PokerAction(playerIndex: 0, type: ActionType.call),
        const PokerAction(playerIndex: 1, type: ActionType.bet, amount: 10),
        const PokerAction(playerIndex: 0, type: ActionType.fold),
      ];
      final states = List.generate(4, (_) => _minimalState());

      final companions =
          HandMapper.actionsToCompanions(7, actions, states);
      expect(companions.length, 3);
    });
  });
}
