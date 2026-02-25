/// Educational context computed from game state for the hand trainer.
///
/// Pure Dart - no Flutter imports.
library;

import 'package:poker_trainer/poker/models/action.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class EducationalContext {
  /// Position label: "BTN", "SB", "UTG", etc.
  final String positionLabel;

  /// Category: "early", "middle", "late", or "blinds".
  final String positionCategory;

  /// Pot odds as a fraction (0.25 = 25%). Null when not facing a bet.
  final double? potOdds;

  /// Human-readable pot odds: "3:1 (25%)". Null when not facing a bet.
  final String? potOddsDisplay;

  /// Stack-to-pot ratio (effective stack / pot).
  final double stackToPotRatio;

  /// Number of non-folded players.
  final int playersInHand;

  /// Active players after current who haven't acted this street.
  final int playersYetToAct;

  /// Natural language situation: "First to act on the Flop".
  final String streetContext;

  /// Explanation of the last action. Null at the very start.
  final ActionExplanation? lastAction;

  /// Street transition summary. Null unless street just changed.
  final StreetSummary? streetSummary;

  const EducationalContext({
    required this.positionLabel,
    required this.positionCategory,
    this.potOdds,
    this.potOddsDisplay,
    required this.stackToPotRatio,
    required this.playersInHand,
    required this.playersYetToAct,
    required this.streetContext,
    this.lastAction,
    this.streetSummary,
  });
}

class ActionExplanation {
  /// e.g. "Player 2 calls 4"
  final String description;

  /// e.g. "Matches the current bet of 4"
  final String mechanical;

  /// e.g. "67% pot" (null for fold/check)
  final String? sizing;

  /// e.g. "Pot now 10, 3 remain"
  final String stateChange;

  const ActionExplanation({
    required this.description,
    required this.mechanical,
    this.sizing,
    required this.stateChange,
  });
}

class StreetSummary {
  /// e.g. "Preflop"
  final String completedStreet;

  /// e.g. "1 raise, 2 callers. Pot: 18"
  final String summary;

  const StreetSummary({
    required this.completedStreet,
    required this.summary,
  });
}

// ---------------------------------------------------------------------------
// Calculator
// ---------------------------------------------------------------------------

class EducationalContextCalculator {
  EducationalContextCalculator._();

  /// Compute the educational context from the current and previous game state.
  static EducationalContext compute({
    required GameState state,
    GameState? previousState,
    required double bigBlind,
  }) {
    final playerIndex = state.currentPlayerIndex;
    final playerCount = state.playerCount;
    final dealerIndex = state.dealerIndex;

    // Position
    final posLabel = _positionLabel(playerIndex, dealerIndex, playerCount,
        straddlePlayerIndex: state.straddlePlayerIndex);
    final posCat = _positionCategory(playerIndex, dealerIndex, playerCount);

    // Pot odds
    final double? potOdds;
    final String? potOddsDisplay;
    final player = state.players[playerIndex];
    final callAmount = state.currentBet - player.currentBet;
    if (callAmount > 0 && !state.isHandComplete) {
      final effectiveCall = callAmount.clamp(0.0, player.stack);
      potOdds = effectiveCall / (state.pot + effectiveCall);
      potOddsDisplay = _formatPotOdds(potOdds);
    } else {
      potOdds = null;
      potOddsDisplay = null;
    }

    // SPR
    final heroStack = player.stack;
    double maxOpponentStack = 0;
    for (final p in state.players) {
      if (p.index != playerIndex && !p.isFolded && p.stack > maxOpponentStack) {
        maxOpponentStack = p.stack;
      }
    }
    final effectiveStack =
        heroStack < maxOpponentStack ? heroStack : maxOpponentStack;
    final spr = state.pot > 0 ? effectiveStack / state.pot : 0.0;

    // Players in hand
    final playersInHand = state.players.where((p) => !p.isFolded).length;

    // Players yet to act
    final yetToAct =
        _playersYetToAct(state, playerIndex);

    // Street context
    final streetCtx = _streetContext(state, callAmount);

    // Action explanation
    final ActionExplanation? lastAction;
    if (previousState != null &&
        state.actionHistory.length > previousState.actionHistory.length) {
      lastAction = _buildActionExplanation(state, previousState);
    } else {
      lastAction = null;
    }

    // Street summary
    final StreetSummary? streetSummary;
    if (previousState != null && state.street != previousState.street) {
      streetSummary = _buildStreetSummary(previousState);
    } else {
      streetSummary = null;
    }

    return EducationalContext(
      positionLabel: posLabel,
      positionCategory: posCat,
      potOdds: potOdds,
      potOddsDisplay: potOddsDisplay,
      stackToPotRatio: spr,
      playersInHand: playersInHand,
      playersYetToAct: yetToAct,
      streetContext: streetCtx,
      lastAction: lastAction,
      streetSummary: streetSummary,
    );
  }

  // -------------------------------------------------------------------------
  // Position helpers
  // -------------------------------------------------------------------------

  /// Maps absolute seat index to a position label.
  ///
  /// When [straddlePlayerIndex] is non-null, that player's label includes
  /// a "STR" suffix (e.g. "UTG (STR)").
  static String _positionLabel(
      int seatIndex, int dealerIndex, int playerCount,
      {int? straddlePlayerIndex}) {
    if (playerCount == 2) {
      // Heads-up: dealer is BTN/SB, other is BB.
      return seatIndex == dealerIndex ? 'BTN (SB)' : 'BB';
    }

    final sbIndex = (dealerIndex + 1) % playerCount;
    final bbIndex = (dealerIndex + 2) % playerCount;

    if (seatIndex == dealerIndex) return 'BTN';
    if (seatIndex == sbIndex) return 'SB';
    if (seatIndex == bbIndex) return 'BB';

    // Remaining positions depend on player count.
    // Walk clockwise from BB+1 to dealer-1 and assign labels.
    final positions = _buildPositionMap(dealerIndex, playerCount);
    final label = positions[seatIndex] ?? 'MP';

    if (straddlePlayerIndex != null && seatIndex == straddlePlayerIndex) {
      return '$label (STR)';
    }
    return label;
  }

  static Map<int, String> _buildPositionMap(int dealerIndex, int playerCount) {
    final map = <int, String>{};
    final sbIndex = (dealerIndex + 1) % playerCount;
    final bbIndex = (dealerIndex + 2) % playerCount;

    map[dealerIndex] = 'BTN';
    map[sbIndex] = 'SB';
    map[bbIndex] = 'BB';

    // Seats between BB+1 and BTN-1 (exclusive), clockwise.
    final earlySeats = <int>[];
    var idx = (bbIndex + 1) % playerCount;
    while (idx != dealerIndex) {
      earlySeats.add(idx);
      idx = (idx + 1) % playerCount;
    }

    // Assign from earliest to latest position.
    // Standard naming for common table sizes:
    // 3: BTN, SB, BB (all assigned above)
    // 4: UTG, BTN, SB, BB
    // 5: UTG, CO, BTN, SB, BB
    // 6: UTG, MP, CO, BTN, SB, BB
    // 7: UTG, MP, HJ, CO, BTN, SB, BB
    // 8: UTG, UTG+1, MP, HJ, CO, BTN, SB, BB
    // 9: UTG, UTG+1, MP, HJ, CO, BTN, SB, BB  (+ LJ)
    // 10: UTG, UTG+1, UTG+2, MP, LJ, HJ, CO, BTN, SB, BB
    final count = earlySeats.length;
    if (count == 0) return map;

    // Name from latest (closest to BTN) backwards.
    final labels = <String>[];
    if (count >= 1) labels.add('CO');
    if (count >= 2) labels.insert(0, 'HJ');
    if (count >= 3) labels.insert(0, 'LJ');
    if (count >= 4) labels.insert(0, 'MP');
    if (count >= 5) labels.insert(0, 'UTG+2');
    if (count >= 6) labels.insert(0, 'UTG+1');
    if (count >= 7) labels.insert(0, 'UTG');

    // If more seats than labels, pad the front with UTG variants.
    while (labels.length < count) {
      labels.insert(0, 'UTG');
    }

    for (var i = 0; i < count; i++) {
      map[earlySeats[i]] = labels[i];
    }
    return map;
  }

  static String _positionCategory(
      int seatIndex, int dealerIndex, int playerCount) {
    final label = _positionLabel(seatIndex, dealerIndex, playerCount);
    if (label == 'SB' || label == 'BB' || label == 'BTN (SB)') return 'blinds';
    if (label == 'BTN' || label == 'CO') return 'late';
    if (label == 'HJ' || label == 'LJ' || label == 'MP') return 'middle';
    return 'early'; // UTG, UTG+1, UTG+2
  }

  // -------------------------------------------------------------------------
  // Pot odds
  // -------------------------------------------------------------------------

  static String _formatPotOdds(double fraction) {
    final pct = (fraction * 100).round();
    // Express as ratio: (1/fraction - 1) : 1
    if (fraction > 0 && fraction < 1) {
      final ratio = (1 / fraction) - 1;
      final ratioStr = ratio >= 10
          ? '${ratio.round()}:1'
          : '${ratio.toStringAsFixed(1)}:1';
      return '$ratioStr ($pct%)';
    }
    return '$pct%';
  }

  // -------------------------------------------------------------------------
  // Players yet to act
  // -------------------------------------------------------------------------

  static int _playersYetToAct(GameState state, int currentIndex) {
    // Total active players excluding the current player, minus those who
    // have already acted this street.
    final totalActiveExcludingCurrent =
        state.players.where((p) => p.isActive && p.index != currentIndex).length;
    final alreadyActed = state.playersActedThisStreet;
    final yetToAct = totalActiveExcludingCurrent - alreadyActed;
    return yetToAct < 0 ? 0 : yetToAct;
  }

  // -------------------------------------------------------------------------
  // Street context
  // -------------------------------------------------------------------------

  static String _streetContext(GameState state, double callAmount) {
    if (state.isHandComplete) return 'Hand complete';

    final streetName = _streetDisplayName(state.street);

    // Check if facing a bet/raise
    if (callAmount > 0) {
      if (state.lastAggressorIndex != null) {
        return 'Facing a raise of ${_chips(callAmount)} $streetName';
      }
      // Preflop with just the BB to call
      if (state.street == Street.preflop &&
          state.currentBet == state.bigBlind) {
        return 'Facing the big blind $streetName';
      }
      return 'Facing a bet of ${_chips(callAmount)} $streetName';
    }

    // Can check — describe position context
    final totalActive =
        state.players.where((p) => p.isActive && p.index != state.currentPlayerIndex).length;
    final acted = state.playersActedThisStreet;

    if (acted == 0) {
      return 'First to act on the $streetName';
    }
    if (totalActive - acted <= 0) {
      return 'Last to act on the $streetName';
    }
    return 'Checked to you on the $streetName';
  }

  static String _streetDisplayName(Street street) {
    return switch (street) {
      Street.preflop => 'Preflop',
      Street.flop => 'Flop',
      Street.turn => 'Turn',
      Street.river => 'River',
      Street.showdown => 'Showdown',
    };
  }

  // -------------------------------------------------------------------------
  // Action explanation
  // -------------------------------------------------------------------------

  static ActionExplanation _buildActionExplanation(
      GameState state, GameState previousState) {
    final newAction = state.actionHistory.last;
    final playerName = state.players[newAction.playerIndex].name;
    final prevPot = previousState.pot;

    // Description
    final desc = switch (newAction.type) {
      ActionType.fold => '$playerName folds',
      ActionType.check => '$playerName checks',
      ActionType.call => '$playerName calls ${_chips(newAction.amount)}',
      ActionType.bet => '$playerName bets ${_chips(newAction.amount)}',
      ActionType.raise =>
        '$playerName raises to ${_chips(newAction.amount)}',
      ActionType.allIn =>
        '$playerName all-in ${_chips(newAction.amount)}',
    };

    // Mechanical meaning
    final mechanical = switch (newAction.type) {
      ActionType.fold => 'Surrenders their hand',
      ActionType.check => 'Passes the action, no chips added',
      ActionType.call =>
        'Matches the current bet of ${_chips(previousState.currentBet)}',
      ActionType.bet => 'Opens the betting at ${_chips(newAction.amount)}',
      ActionType.raise =>
        'Increases the bet from ${_chips(previousState.currentBet)} to ${_chips(newAction.amount)}',
      ActionType.allIn =>
        'Puts all remaining chips in (${_chips(newAction.amount)})',
    };

    // Sizing as % of pot (null for fold/check)
    final String? sizing;
    if (newAction.type == ActionType.fold ||
        newAction.type == ActionType.check) {
      sizing = null;
    } else {
      final chipsMoved = switch (newAction.type) {
        ActionType.call => newAction.amount,
        ActionType.bet => newAction.amount,
        ActionType.raise =>
          newAction.amount - previousState.players[newAction.playerIndex].currentBet,
        ActionType.allIn => newAction.amount,
        _ => 0.0,
      };
      if (prevPot > 0) {
        final pctOfPot = (chipsMoved / prevPot * 100).round();
        sizing = '$pctOfPot% pot';
      } else {
        sizing = null;
      }
    }

    // State change
    final remainCount = state.players.where((p) => !p.isFolded).length;
    final stateChange = 'Pot now ${_chips(state.pot)}, $remainCount remain';

    return ActionExplanation(
      description: desc,
      mechanical: mechanical,
      sizing: sizing,
      stateChange: stateChange,
    );
  }

  // -------------------------------------------------------------------------
  // Street summary
  // -------------------------------------------------------------------------

  static StreetSummary _buildStreetSummary(GameState previousState) {
    final completedStreet = _streetDisplayName(previousState.street);

    // Use streetStartActionIndex to extract only this street's actions.
    final allActions = previousState.actionHistory;
    final startIdx = previousState.streetStartActionIndex;
    final streetActions = startIdx < allActions.length
        ? allActions.sublist(startIdx)
        : allActions;

    int raises = 0;
    int calls = 0;
    int folds = 0;
    int checks = 0;

    for (final a in streetActions) {
      switch (a.type) {
        case ActionType.raise:
          raises++;
        case ActionType.bet:
          raises++; // bets and raises both count as aggression
        case ActionType.call:
          calls++;
        case ActionType.fold:
          folds++;
        case ActionType.check:
          checks++;
        case ActionType.allIn:
          raises++; // count as aggression
      }
    }

    final parts = <String>[];
    if (raises > 0) parts.add('$raises ${raises == 1 ? "raise" : "raises"}');
    if (calls > 0) parts.add('$calls ${calls == 1 ? "caller" : "callers"}');
    if (folds > 0) parts.add('$folds ${folds == 1 ? "fold" : "folds"}');
    if (checks > 0) parts.add('$checks ${checks == 1 ? "check" : "checks"}');

    final summary =
        '${parts.isEmpty ? "No action" : parts.join(", ")}. Pot: ${_chips(previousState.pot)}';

    return StreetSummary(
      completedStreet: completedStreet,
      summary: summary,
    );
  }

  // -------------------------------------------------------------------------
  // Formatting
  // -------------------------------------------------------------------------

  static String _chips(double amount) {
    if (amount == amount.roundToDouble() && amount < 10000) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }
}
