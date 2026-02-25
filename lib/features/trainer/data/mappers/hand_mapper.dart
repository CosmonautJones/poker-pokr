import 'package:drift/drift.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/database/converters/player_config_list_converter.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Maps between database objects and domain/engine objects.
class HandMapper {
  HandMapper._();

  /// Convert a saved [Hand] to a [HandSetup] for replay.
  static HandSetup handToSetup(Hand hand) {
    final configs = hand.playerConfigs;
    // Sort by seatIndex to ensure correct ordering.
    final sorted = List<PlayerConfig>.of(configs)
      ..sort((a, b) => a.seatIndex.compareTo(b.seatIndex));

    return HandSetup(
      playerCount: hand.playerCount,
      smallBlind: hand.smallBlind,
      bigBlind: hand.bigBlind,
      ante: hand.ante,
      dealerIndex: 0, // Default: first player is dealer
      playerNames: sorted.map((c) => c.name).toList(),
      stacks: sorted.map((c) => c.stack).toList(),
      gameType: GameType.values[hand.gameType],
      straddleEnabled: hand.straddle > 0,
      straddleMultiplier:
          hand.straddle > 0 ? hand.straddle / hand.bigBlind : 2.0,
    );
  }

  /// Convert saved [HandAction] records to a list of [PokerAction].
  static List<PokerAction> actionsFromDb(List<HandAction> dbActions) {
    return dbActions.map((a) {
      return PokerAction(
        playerIndex: a.playerPosition,
        type: ActionType.values[a.actionType],
        amount: a.amount,
      );
    }).toList();
  }

  /// Convert a [HandSetup] to a [HandsCompanion] for database insertion.
  static HandsCompanion setupToCompanion(HandSetup setup, {String? title}) {
    final configs = List.generate(setup.playerCount, (i) {
      return PlayerConfig(
        name: setup.playerNames[i],
        stack: setup.stacks[i],
        seatIndex: i,
      );
    });

    return HandsCompanion.insert(
      playerCount: setup.playerCount,
      smallBlind: setup.smallBlind,
      bigBlind: setup.bigBlind,
      ante: Value(setup.ante),
      playerConfigs: configs,
      communityCards: const <int>[],
      title: Value(title),
      gameType: Value(setup.gameType.index),
      straddle: Value(setup.straddleAmount),
    );
  }

  /// Convert a list of [PokerAction] and corresponding [GameState] snapshots
  /// to [HandActionsCompanion] records for database insertion.
  ///
  /// [states] should contain one more element than [actions] (the initial state
  /// plus one state after each action). The pot after each action comes from
  /// `states[i + 1].pot`.
  /// Convert a list of [PokerAction] and corresponding [GameState] snapshots
  /// to [HandActionsCompanion] records for database insertion.
  ///
  /// [startIndex] offsets the sequenceIndex values so branch actions continue
  /// from the correct position (defaults to 0 for the original line).
  static List<HandActionsCompanion> actionsToCompanions(
    int handId,
    List<PokerAction> actions,
    List<GameState> states, {
    int startIndex = 0,
  }) {
    return List.generate(actions.length, (i) {
      final action = actions[i];
      // The state *after* this action is at index i + 1.
      final potAfter =
          (i + 1 < states.length) ? states[i + 1].pot : states.last.pot;
      // Determine the street from the state *before* the action (index i).
      final street = states[i].street;

      return HandActionsCompanion.insert(
        handId: handId,
        sequenceIndex: startIndex + i,
        street: street.index,
        playerPosition: action.playerIndex,
        actionType: action.type.index,
        amount: Value(action.amount),
        potAfterAction: Value(potAfter),
      );
    });
  }

  /// Build a [HandsCompanion] that also captures the final community cards.
  ///
  /// If [parentHandId] and [branchAtActionIndex] are provided, the companion
  /// represents a branch of an existing hand.
  static HandsCompanion gameStateToCompanion(
    HandSetup setup,
    GameState finalState, {
    String? title,
    int? parentHandId,
    int? branchAtActionIndex,
  }) {
    final configs = List.generate(setup.playerCount, (i) {
      return PlayerConfig(
        name: setup.playerNames[i],
        stack: setup.stacks[i],
        seatIndex: i,
      );
    });

    final communityCardValues =
        finalState.communityCards.map((c) => c.value).toList();

    return HandsCompanion.insert(
      playerCount: setup.playerCount,
      smallBlind: setup.smallBlind,
      bigBlind: setup.bigBlind,
      ante: Value(setup.ante),
      playerConfigs: configs,
      communityCards: communityCardValues,
      title: Value(title),
      parentHandId: Value(parentHandId),
      branchAtActionIndex: Value(branchAtActionIndex),
      gameType: Value(setup.gameType.index),
      straddle: Value(setup.straddleAmount),
    );
  }
}
