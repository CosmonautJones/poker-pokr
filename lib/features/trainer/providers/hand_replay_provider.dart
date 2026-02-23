import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';
import 'package:poker_trainer/poker/history/state_history.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

/// Immutable snapshot of the hand replay state exposed to the UI.
class HandReplayState {
  final GameState gameState;
  final LegalActionSet legalActions;
  final bool canUndo;
  final bool canRedo;
  final bool isComplete;
  final List<PokerAction> actionHistory;

  const HandReplayState({
    required this.gameState,
    required this.legalActions,
    required this.canUndo,
    required this.canRedo,
    required this.isComplete,
    required this.actionHistory,
  });
}

/// Manages an in-progress hand replay with undo/redo support.
///
/// Created via [handReplayProvider] with a [HandSetup] argument.
class HandReplayNotifier extends AutoDisposeFamilyNotifier<HandReplayState, HandSetup> {
  late StateHistory<GameState> _history;

  @override
  HandReplayState build(HandSetup arg) {
    final initialState = GameEngine.createInitialState(
      playerCount: arg.playerCount,
      smallBlind: arg.smallBlind,
      bigBlind: arg.bigBlind,
      ante: arg.ante,
      dealerIndex: arg.dealerIndex,
      names: arg.playerNames,
      stacks: arg.stacks,
    );
    _history = StateHistory<GameState>(initialState);
    return _buildState(initialState);
  }

  HandReplayState _buildState(GameState gs) {
    return HandReplayState(
      gameState: gs,
      legalActions: gs.isHandComplete
          ? const LegalActionSet()
          : LegalActionSet.compute(gs),
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      isComplete: gs.isHandComplete,
      actionHistory: gs.actionHistory,
    );
  }

  /// Apply a poker action and advance the game state.
  void applyAction(PokerAction action) {
    final newState = GameEngine.applyAction(_history.current, action);
    _history.push(newState);
    state = _buildState(newState);
  }

  /// Undo the last action.
  void undo() {
    final prev = _history.undo();
    if (prev != null) state = _buildState(prev);
  }

  /// Redo a previously undone action.
  void redo() {
    final next = _history.redo();
    if (next != null) state = _buildState(next);
  }

  /// Returns all game states in the history (for saving).
  List<GameState> get allStates => _history.states;
}

final handReplayProvider = NotifierProvider.autoDispose
    .family<HandReplayNotifier, HandReplayState, HandSetup>(
  HandReplayNotifier.new,
);
