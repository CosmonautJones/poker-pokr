import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/providers/hand_replay_provider.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/street.dart';

HandSetup _defaultSetup({int playerCount = 6}) =>
    HandSetup.defaults(playerCount: playerCount);

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  HandReplayState readState(HandSetup setup) =>
      container.read(handReplayProvider(setup));
  HandReplayNotifier readNotifier(HandSetup setup) =>
      container.read(handReplayProvider(setup).notifier);

  group('HandReplayNotifier', () {
    group('initial state', () {
      test('starts on preflop', () {
        final setup = _defaultSetup();
        expect(readState(setup).gameState.street, Street.preflop);
      });

      test('hand is not complete initially', () {
        final setup = _defaultSetup();
        expect(readState(setup).isComplete, false);
      });

      test('cannot undo at start', () {
        final setup = _defaultSetup();
        expect(readState(setup).canUndo, false);
      });

      test('cannot redo at start', () {
        final setup = _defaultSetup();
        expect(readState(setup).canRedo, false);
      });

      test('action history is empty', () {
        final setup = _defaultSetup();
        expect(readState(setup).actionHistory, isEmpty);
      });

      test('has one branch (Line A)', () {
        final setup = _defaultSetup();
        expect(readState(setup).branches.length, 1);
        expect(readState(setup).branches[0].label, 'Line A');
      });

      test('active branch is 0', () {
        final setup = _defaultSetup();
        expect(readState(setup).activeBranchIndex, 0);
      });

      test('legal actions are available', () {
        final setup = _defaultSetup();
        final legal = readState(setup).legalActions;
        // UTG should be able to fold and call at minimum.
        expect(legal.canFold, isTrue);
      });

      test('educational context is computed', () {
        final setup = _defaultSetup();
        expect(readState(setup).educationalContext.positionLabel, isNotEmpty);
      });

      test('player count matches setup', () {
        final setup = _defaultSetup(playerCount: 4);
        expect(readState(setup).gameState.playerCount, 4);
      });
    });

    group('applyAction', () {
      test('fold advances to next player', () {
        final setup = _defaultSetup();
        final beforeIdx = readState(setup).gameState.currentPlayerIndex;
        readNotifier(setup).applyAction(PokerAction(
          playerIndex: beforeIdx,
          type: ActionType.fold,
        ));
        // After folding, action history should have one entry.
        expect(readState(setup).actionHistory.length, 1);
        expect(readState(setup).actionHistory[0].type, ActionType.fold);
      });

      test('can undo after an action', () {
        final setup = _defaultSetup();
        readNotifier(setup).applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        expect(readState(setup).canUndo, isTrue);
      });

      test('call action decreases stack and increases pot', () {
        final setup = _defaultSetup();
        final gs = readState(setup).gameState;
        final playerIdx = gs.currentPlayerIndex;
        final potBefore = gs.pot;

        readNotifier(setup).applyAction(PokerAction(
          playerIndex: playerIdx,
          type: ActionType.call,
          amount: gs.currentBet,
        ));

        expect(readState(setup).gameState.pot, greaterThan(potBefore));
      });

      test('everyone folds except one completes the hand', () {
        final setup = _defaultSetup(playerCount: 3);
        final notifier = readNotifier(setup);

        // Fold until only one player remains.
        // Player count = 3. Need 2 folds.
        for (int i = 0; i < 2; i++) {
          final gs = readState(setup).gameState;
          if (gs.isHandComplete) break;
          notifier.applyAction(PokerAction(
            playerIndex: gs.currentPlayerIndex,
            type: ActionType.fold,
          ));
        }

        expect(readState(setup).isComplete, isTrue);
      });

      test('completed hand has no legal actions', () {
        final setup = _defaultSetup(playerCount: 2);
        final notifier = readNotifier(setup);

        // Fold in heads-up completes the hand.
        final gs = readState(setup).gameState;
        notifier.applyAction(PokerAction(
          playerIndex: gs.currentPlayerIndex,
          type: ActionType.fold,
        ));

        expect(readState(setup).isComplete, isTrue);
        expect(readState(setup).legalActions.canFold, isFalse);
        expect(readState(setup).legalActions.canCheck, isFalse);
      });
    });

    group('undo/redo', () {
      test('undo restores previous state', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);
        final stateBefore = readState(setup).gameState;

        notifier.applyAction(PokerAction(
          playerIndex: stateBefore.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.undo();

        expect(
          readState(setup).gameState.currentPlayerIndex,
          stateBefore.currentPlayerIndex,
        );
        expect(readState(setup).actionHistory, isEmpty);
      });

      test('redo re-applies undone action', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.undo();
        expect(readState(setup).canRedo, isTrue);

        notifier.redo();
        expect(readState(setup).actionHistory.length, 1);
        expect(readState(setup).canRedo, isFalse);
      });

      test('undo at start does nothing', () {
        final setup = _defaultSetup();
        readNotifier(setup).undo();
        // Should not crash, state unchanged.
        expect(readState(setup).actionHistory, isEmpty);
      });

      test('redo without undo does nothing', () {
        final setup = _defaultSetup();
        readNotifier(setup).redo();
        expect(readState(setup).actionHistory, isEmpty);
      });

      test('new action after undo clears redo history', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        // Action 1: fold.
        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.undo();
        expect(readState(setup).canRedo, isTrue);

        // New action: call instead.
        final gs = readState(setup).gameState;
        notifier.applyAction(PokerAction(
          playerIndex: gs.currentPlayerIndex,
          type: ActionType.call,
          amount: gs.currentBet,
        ));
        expect(readState(setup).canRedo, isFalse);
      });
    });

    group('branching', () {
      test('forkAtAction creates a new branch', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        // Apply two actions.
        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));

        // Fork after action 1.
        notifier.forkAtAction(1);

        expect(readState(setup).branches.length, 2);
        expect(readState(setup).activeBranchIndex, 1);
        expect(readState(setup).branches[1].label, 'Line B');
        expect(readState(setup).branches[1].forkAtActionIndex, 1);
      });

      test('forked branch starts with actions up to fork point', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));

        notifier.forkAtAction(1);
        // Forked branch should have 1 action (up to fork point).
        expect(readState(setup).actionHistory.length, 1);
      });

      test('switchToBranch changes active branch', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.forkAtAction(1);

        // Now on branch 1. Switch back to 0.
        notifier.switchToBranch(0);
        expect(readState(setup).activeBranchIndex, 0);
      });

      test('switchToBranch ignores invalid index', () {
        final setup = _defaultSetup();
        readNotifier(setup).switchToBranch(99);
        // Should not crash, branch stays at 0.
        expect(readState(setup).activeBranchIndex, 0);
      });

      test('switchToBranch ignores negative index', () {
        final setup = _defaultSetup();
        readNotifier(setup).switchToBranch(-1);
        expect(readState(setup).activeBranchIndex, 0);
      });

      test('new actions can be applied on forked branch', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.forkAtAction(1);

        // Apply a different action on the new branch.
        final gs = readState(setup).gameState;
        notifier.applyAction(PokerAction(
          playerIndex: gs.currentPlayerIndex,
          type: ActionType.call,
          amount: gs.currentBet,
        ));

        expect(readState(setup).actionHistory.length, 2);
        expect(readState(setup).actionHistory[1].type, ActionType.call);
      });

      test('branch labels follow alphabetical order', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));

        notifier.forkAtAction(1);
        expect(readState(setup).branches[1].label, 'Line B');

        notifier.forkAtAction(1);
        expect(readState(setup).branches[2].label, 'Line C');
      });
    });

    group('loadBranch', () {
      test('loads a saved branch with replayed actions', () {
        final setup = _defaultSetup(playerCount: 3);
        final notifier = readNotifier(setup);

        // Apply some actions on the main line.
        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));

        // Load a branch forked at action 0 with a different action.
        final gsAtStart = notifier.allStates[0]; // Initial state.
        final actions = [
          PokerAction(
            playerIndex: gsAtStart.currentPlayerIndex,
            type: ActionType.call,
            amount: gsAtStart.currentBet,
          ),
        ];

        notifier.loadBranch(
          forkAtActionIndex: 0,
          actions: actions,
          dbHandId: 42,
        );

        expect(notifier.branchCount, 2);
        expect(readState(setup).branches[1].forkAtActionIndex, 0);
      });
    });

    group('allBranches / allStates', () {
      test('allStates returns history for active branch', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));

        // Should have 2 states: initial + after fold.
        expect(notifier.allStates.length, 2);
      });

      test('allBranches returns data for all branches', () {
        final setup = _defaultSetup();
        final notifier = readNotifier(setup);

        notifier.applyAction(PokerAction(
          playerIndex: readState(setup).gameState.currentPlayerIndex,
          type: ActionType.fold,
        ));
        notifier.forkAtAction(1);

        final branches = notifier.allBranches;
        expect(branches.length, 2);
        // Each branch should have (BranchInfo, List<GameState>).
        expect(branches[0].$1.label, 'Line A');
        expect(branches[1].$1.label, 'Line B');
      });
    });
  });
}
