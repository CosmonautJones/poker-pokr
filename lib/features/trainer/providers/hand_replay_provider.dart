import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/trainer/domain/branch_info.dart';
import 'package:poker_trainer/features/trainer/domain/educational_context.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/engine/game_engine.dart';
import 'package:poker_trainer/poker/engine/legal_actions.dart';
import 'package:poker_trainer/poker/history/state_history.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

/// Immutable snapshot of the hand replay state exposed to the UI.
class HandReplayState {
  final GameState gameState;
  final LegalActionSet legalActions;
  final bool canUndo;
  final bool canRedo;
  final bool isComplete;
  final List<PokerAction> actionHistory;
  final int activeBranchIndex;
  final List<BranchInfo> branches;
  final EducationalContext educationalContext;

  const HandReplayState({
    required this.gameState,
    required this.legalActions,
    required this.canUndo,
    required this.canRedo,
    required this.isComplete,
    required this.actionHistory,
    this.activeBranchIndex = 0,
    this.branches = const [],
    required this.educationalContext,
  });
}

/// Manages an in-progress hand replay with undo/redo and branching support.
///
/// Created via [handReplayProvider] with a [HandSetup] argument.
class HandReplayNotifier
    extends AutoDisposeFamilyNotifier<HandReplayState, HandSetup> {
  final List<StateHistory<GameState>> _branches = [];
  final List<BranchInfo> _branchInfos = [];
  int _activeBranchIndex = 0;

  /// The active branch's history.
  StateHistory<GameState> get _history => _branches[_activeBranchIndex];

  @override
  HandReplayState build(HandSetup arg) {
    // Convert hole cards: if all players have cards assigned, pass them in.
    // Otherwise, let the engine deal randomly for unassigned players.
    List<List<PokerCard>>? resolvedHoleCards;
    if (arg.holeCards != null) {
      final expectedCards = arg.gameType.holeCardCount;
      final allAssigned = arg.holeCards!
          .every((h) => h != null && h.length == expectedCards);
      if (allAssigned) {
        resolvedHoleCards = arg.holeCards!.map((h) => h!).toList();
      } else {
        // Some players have cards, some don't. Pre-deal from a deck,
        // avoiding the already-assigned cards.
        final deck = Deck();
        for (final h in arg.holeCards!) {
          if (h != null) deck.remove(h);
        }
        resolvedHoleCards = List.generate(arg.playerCount, (i) {
          final existing = arg.holeCards![i];
          if (existing != null && existing.length == expectedCards) {
            return existing;
          }
          return deck.dealMany(expectedCards);
        });
      }
    }

    var initialState = GameEngine.createInitialState(
      playerCount: arg.playerCount,
      smallBlind: arg.smallBlind,
      bigBlind: arg.bigBlind,
      ante: arg.ante,
      dealerIndex: arg.dealerIndex,
      names: arg.playerNames,
      stacks: arg.stacks,
      holeCards: resolvedHoleCards,
      gameType: arg.gameType,
      straddle: arg.straddleAmount,
    );

    // For lesson scenarios with pre-determined community cards, replace
    // the shuffled deck with the stacked one.
    if (arg.stackedDeck != null) {
      initialState = initialState.copyWith(deck: arg.stackedDeck);
    }

    _branches.clear();
    _branchInfos.clear();
    _branches.add(StateHistory<GameState>(initialState));
    _branchInfos.add(const BranchInfo(label: 'Line A', forkAtActionIndex: 0));
    _activeBranchIndex = 0;
    return _buildState(initialState);
  }

  HandReplayState _buildState(GameState gs) {
    final previousGs = _history.currentIndex > 0
        ? _history.states[_history.currentIndex - 1]
        : null;
    return HandReplayState(
      gameState: gs,
      legalActions: gs.isHandComplete
          ? const LegalActionSet()
          : LegalActionSet.compute(gs),
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
      isComplete: gs.isHandComplete,
      actionHistory: gs.actionHistory,
      activeBranchIndex: _activeBranchIndex,
      branches: List.unmodifiable(_branchInfos),
      educationalContext: EducationalContextCalculator.compute(
        state: gs,
        previousState: previousGs,
        bigBlind: gs.bigBlind,
      ),
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

  /// Fork the current branch at [actionIndex], creating a new branch.
  ///
  /// [actionIndex] is the number of actions to keep (0-based). For example,
  /// forkAtAction(3) keeps the first 3 actions and lets the user choose a
  /// different action as the 4th.
  void forkAtAction(int actionIndex) {
    // states[0] = initial, states[N] = after N actions.
    // forkAt(actionIndex) gives states[0..actionIndex].
    final forked = _branches[_activeBranchIndex].forkAt(actionIndex);
    final label = _branchLabel(_branchInfos.length);
    _branches.add(forked);
    _branchInfos
        .add(BranchInfo(label: label, forkAtActionIndex: actionIndex));
    _activeBranchIndex = _branches.length - 1;
    state = _buildState(forked.current);
  }

  /// Switch to a different branch by index.
  void switchToBranch(int index) {
    if (index < 0 || index >= _branches.length) return;
    _activeBranchIndex = index;
    state = _buildState(_history.current);
  }

  /// Load a saved branch by forking the original line at [forkAtActionIndex]
  /// and replaying [actions] on top.
  void loadBranch({
    required int forkAtActionIndex,
    required List<PokerAction> actions,
    int? dbHandId,
  }) {
    final forked = _branches[0].forkAt(forkAtActionIndex);
    for (final action in actions) {
      final newState = GameEngine.applyAction(forked.current, action);
      forked.push(newState);
    }
    final label = _branchLabel(_branchInfos.length);
    _branches.add(forked);
    _branchInfos.add(BranchInfo(
      label: label,
      dbHandId: dbHandId,
      forkAtActionIndex: forkAtActionIndex,
    ));
  }

  /// Returns all game states in the active branch's history (for saving).
  List<GameState> get allStates => _history.states;

  /// Returns branch data for all branches — used when saving.
  ///
  /// Each entry is `(BranchInfo, List<GameState>)` where the states include
  /// the initial state plus one state per action.
  List<(BranchInfo, List<GameState>)> get allBranches {
    return List.generate(_branches.length, (i) {
      return (_branchInfos[i], _branches[i].states);
    });
  }

  /// Number of branches.
  int get branchCount => _branches.length;

  static String _branchLabel(int index) {
    // Line A, Line B, ..., Line Z, Line AA, ...
    if (index < 26) {
      return 'Line ${String.fromCharCode(65 + index)}';
    }
    return 'Line ${index + 1}';
  }
}

final handReplayProvider = NotifierProvider.autoDispose
    .family<HandReplayNotifier, HandReplayState, HandSetup>(
  HandReplayNotifier.new,
);
