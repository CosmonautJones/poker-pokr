/// Core game engine: creates initial states and applies actions.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/action.dart';
import '../models/card.dart';
import '../models/game_state.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import '../models/street.dart';
import 'hand_evaluator.dart';
import 'legal_actions.dart';
import 'pot_calculator.dart';
import 'street_progression.dart';

class GameEngine {
  // ---------------------------------------------------------------------------
  // Initial state creation
  // ---------------------------------------------------------------------------

  /// Create the initial [GameState] for a new hand.
  ///
  /// [playerCount]  Number of players (2-10).
  /// [smallBlind]   Small blind amount.
  /// [bigBlind]     Big blind amount.
  /// [ante]         Per-player ante (default 0).
  /// [dealerIndex]  Seat index of the dealer button.
  /// [holeCards]    Optional pre-assigned hole cards per player.
  /// [stacks]       Optional starting stacks (defaults to 100 * BB each).
  /// [names]        Optional player names.
  /// [deckSeed]     Optional seed for deterministic deck shuffling.
  /// [gameType]     Game variant (default: Texas Hold'em).
  /// [straddle]     Straddle amount (0 = no straddle). Ignored heads-up.
  static GameState createInitialState({
    required int playerCount,
    required double smallBlind,
    required double bigBlind,
    double ante = 0,
    required int dealerIndex,
    List<List<PokerCard>>? holeCards,
    List<double>? stacks,
    List<String>? names,
    int? deckSeed,
    GameType gameType = GameType.texasHoldem,
    double straddle = 0,
  }) {
    assert(playerCount >= 2 && playerCount <= 10);
    assert(dealerIndex >= 0 && dealerIndex < playerCount);

    final isHeadsUp = playerCount == 2;

    // --- Determine blind positions ---
    // Heads-up: dealer posts SB, other player posts BB.
    // Multi-way: SB is dealer+1, BB is dealer+2.
    final int sbIndex;
    final int bbIndex;
    if (isHeadsUp) {
      sbIndex = dealerIndex;
      bbIndex = (dealerIndex + 1) % playerCount;
    } else {
      sbIndex = (dealerIndex + 1) % playerCount;
      bbIndex = (dealerIndex + 2) % playerCount;
    }

    // Straddle: UTG player (seat after BB). Only for 3+ players.
    final bool hasStraddle = straddle > 0 && !isHeadsUp;
    final int? straddleIndex =
        hasStraddle ? (bbIndex + 1) % playerCount : null;

    // --- Create deck and deal hole cards ---
    final deck = Deck(seed: deckSeed);

    // If hole cards were provided, remove them from the deck.
    if (holeCards != null) {
      for (final hand in holeCards) {
        deck.remove(hand);
      }
    }

    final cardsPerPlayer = gameType.holeCardCount;

    // --- Build player states ---
    double totalPot = 0;
    final players = <PlayerState>[];

    for (int i = 0; i < playerCount; i++) {
      final defaultStack = stacks != null ? stacks[i] : bigBlind * 100;
      final name = names != null ? names[i] : 'Player ${i + 1}';
      var stack = defaultStack;
      double currentBet = 0;
      double totalInvested = 0;
      bool isAllIn = false;

      // Post ante.
      if (ante > 0) {
        final anteAmount = ante.clamp(0, stack);
        stack -= anteAmount;
        totalPot += anteAmount;
        totalInvested += anteAmount;
        if (stack <= 0) isAllIn = true;
      }

      // Post blinds.
      if (i == sbIndex && !isAllIn) {
        final double sbAmount = smallBlind.clamp(0.0, stack).toDouble();
        stack -= sbAmount;
        currentBet = sbAmount;
        totalInvested += sbAmount;
        totalPot += sbAmount;
        if (stack <= 0) isAllIn = true;
      } else if (i == bbIndex && !isAllIn) {
        final double bbAmount = bigBlind.clamp(0.0, stack).toDouble();
        stack -= bbAmount;
        currentBet = bbAmount;
        totalInvested += bbAmount;
        totalPot += bbAmount;
        if (stack <= 0) isAllIn = true;
      }

      // Post straddle.
      if (hasStraddle && i == straddleIndex && !isAllIn) {
        final double straddleAmount = straddle.clamp(0.0, stack).toDouble();
        stack -= straddleAmount;
        currentBet = straddleAmount;
        totalInvested += straddleAmount;
        totalPot += straddleAmount;
        if (stack <= 0) isAllIn = true;
      }

      // Deal hole cards.
      final hand =
          holeCards != null ? holeCards[i] : deck.dealMany(cardsPerPlayer);

      players.add(PlayerState(
        index: i,
        name: name,
        stack: stack,
        holeCards: hand,
        currentBet: currentBet,
        totalInvested: totalInvested,
        isAllIn: isAllIn,
      ));
    }

    // --- Determine first player to act preflop ---
    // Heads-up: dealer (SB) acts first preflop.
    // Multi-way without straddle: UTG = player after BB.
    // Multi-way with straddle: first to act is player after straddler;
    //   straddler acts last preflop (gets "option").
    final int firstToAct;
    final double effectiveCurrentBet;
    final double effectiveLastRaise;

    if (isHeadsUp) {
      firstToAct = dealerIndex; // dealer = SB acts first preflop
      effectiveCurrentBet = bigBlind;
      effectiveLastRaise = bigBlind;
    } else if (hasStraddle) {
      firstToAct = _nextActivePlayer(players, straddleIndex!);
      effectiveCurrentBet = straddle;
      // The raise increment from BB to straddle determines min-raise.
      effectiveLastRaise = straddle - bigBlind;
    } else {
      firstToAct = _nextActivePlayer(players, bbIndex);
      effectiveCurrentBet = bigBlind;
      effectiveLastRaise = bigBlind;
    }

    return GameState(
      players: players,
      deck: deck,
      street: Street.preflop,
      pot: totalPot,
      currentPlayerIndex: firstToAct,
      currentBet: effectiveCurrentBet,
      lastRaiseSize: effectiveLastRaise,
      smallBlind: smallBlind,
      bigBlind: bigBlind,
      ante: ante,
      dealerIndex: dealerIndex,
      gameType: gameType,
      straddle: hasStraddle ? straddle : 0,
      straddlePlayerIndex: straddleIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // Action application
  // ---------------------------------------------------------------------------

  /// Apply a [PokerAction] to the current [GameState], returning the new state.
  ///
  /// Throws [StateError] if the action is illegal.
  static GameState applyAction(GameState state, PokerAction action) {
    if (state.isHandComplete) {
      throw StateError('Cannot apply action: hand is already complete.');
    }

    if (action.playerIndex != state.currentPlayerIndex) {
      throw StateError(
        'It is player ${state.currentPlayerIndex}\'s turn, '
        'not player ${action.playerIndex}\'s.',
      );
    }

    // Validate the action against the legal action set.
    _validateAction(state, action);

    // Apply the specific action type.
    GameState newState;
    switch (action.type) {
      case ActionType.fold:
        newState = _applyFold(state, action);
        break;
      case ActionType.check:
        newState = _applyCheck(state, action);
        break;
      case ActionType.call:
        newState = _applyCall(state, action);
        break;
      case ActionType.bet:
        newState = _applyBet(state, action);
        break;
      case ActionType.raise:
        newState = _applyRaise(state, action);
        break;
      case ActionType.allIn:
        newState = _applyAllIn(state, action);
        break;
    }

    // Record the action in history.
    newState = newState.copyWith(
      actionHistory: [...newState.actionHistory, action],
    );

    // --- Post-action progression ---
    return _postAction(newState);
  }

  // ---------------------------------------------------------------------------
  // Action implementations
  // ---------------------------------------------------------------------------

  static GameState _applyFold(GameState state, PokerAction action) {
    final player = state.players[action.playerIndex];
    final updatedPlayers = _updatePlayer(
      state.players,
      player.copyWith(isFolded: true),
    );
    return state.copyWith(
      players: updatedPlayers,
      playersActedThisStreet: state.playersActedThisStreet + 1,
    );
  }

  static GameState _applyCheck(GameState state, PokerAction action) {
    return state.copyWith(
      playersActedThisStreet: state.playersActedThisStreet + 1,
    );
  }

  static GameState _applyCall(GameState state, PokerAction action) {
    final player = state.players[action.playerIndex];
    final toCall = state.currentBet - player.currentBet;
    final actualCall = toCall.clamp(0, player.stack);
    final newStack = player.stack - actualCall;
    final isAllIn = newStack <= 0;

    final updatedPlayer = player.copyWith(
      stack: newStack,
      currentBet: player.currentBet + actualCall,
      totalInvested: player.totalInvested + actualCall,
      isAllIn: isAllIn,
    );

    return state.copyWith(
      players: _updatePlayer(state.players, updatedPlayer),
      pot: state.pot + actualCall,
      playersActedThisStreet: state.playersActedThisStreet + 1,
    );
  }

  static GameState _applyBet(GameState state, PokerAction action) {
    final player = state.players[action.playerIndex];
    final betAmount = action.amount;
    final newStack = player.stack - betAmount;
    final isAllIn = newStack <= 0;

    final updatedPlayer = player.copyWith(
      stack: newStack < 0 ? 0 : newStack,
      currentBet: player.currentBet + betAmount,
      totalInvested: player.totalInvested + betAmount,
      isAllIn: isAllIn,
    );

    return state.copyWith(
      players: _updatePlayer(state.players, updatedPlayer),
      pot: state.pot + betAmount,
      currentBet: updatedPlayer.currentBet,
      lastRaiseSize: betAmount,
      lastAggressorIndex: () => action.playerIndex,
      playersActedThisStreet: 1, // reset: others need to respond
    );
  }

  static GameState _applyRaise(GameState state, PokerAction action) {
    final player = state.players[action.playerIndex];
    // action.amount is the TOTAL raise-to amount.
    final raiseTo = action.amount;
    final additionalChips = raiseTo - player.currentBet;
    final newStack = player.stack - additionalChips;
    final isAllIn = newStack <= 0;
    final raiseSize = raiseTo - state.currentBet;

    final updatedPlayer = player.copyWith(
      stack: newStack < 0 ? 0 : newStack,
      currentBet: raiseTo,
      totalInvested: player.totalInvested + additionalChips,
      isAllIn: isAllIn,
    );

    return state.copyWith(
      players: _updatePlayer(state.players, updatedPlayer),
      pot: state.pot + additionalChips,
      currentBet: raiseTo,
      lastRaiseSize: raiseSize > state.lastRaiseSize ? raiseSize : state.lastRaiseSize,
      lastAggressorIndex: () => action.playerIndex,
      playersActedThisStreet: 1, // reset: others need to respond
    );
  }

  static GameState _applyAllIn(GameState state, PokerAction action) {
    final player = state.players[action.playerIndex];
    final allInAmount = player.stack;
    final newBet = player.currentBet + allInAmount;

    final updatedPlayer = player.copyWith(
      stack: 0,
      currentBet: newBet,
      totalInvested: player.totalInvested + allInAmount,
      isAllIn: true,
    );

    // Determine if this acts as a bet / raise / call.
    final wasRaise = newBet > state.currentBet;
    final raiseSize = newBet - state.currentBet;

    // Only reset playersActedThisStreet if this is a raise (re-opens action).
    // A "short all-in" that doesn't meet the min raise does NOT re-open
    // action. However, for simplicity and correctness we check if the all-in
    // exceeds current bet.
    final bool reopensAction = wasRaise && raiseSize >= state.lastRaiseSize;

    return state.copyWith(
      players: _updatePlayer(state.players, updatedPlayer),
      pot: state.pot + allInAmount,
      currentBet: wasRaise ? newBet : state.currentBet,
      lastRaiseSize: wasRaise && raiseSize > state.lastRaiseSize
          ? raiseSize
          : state.lastRaiseSize,
      lastAggressorIndex:
          wasRaise ? () => action.playerIndex : null,
      playersActedThisStreet:
          reopensAction ? 1 : state.playersActedThisStreet + 1,
    );
  }

  // ---------------------------------------------------------------------------
  // Post-action progression
  // ---------------------------------------------------------------------------

  static GameState _postAction(GameState state) {
    // 1. Check if only one player remains (everyone else folded).
    final inHand = state.players.where((p) => !p.isFolded).toList();
    if (inHand.length <= 1) {
      return _completeHand(state, inHand.map((p) => p.index).toList());
    }

    // 2. Check if the betting round is complete.
    if (StreetProgression.isBettingRoundComplete(state)) {
      // Check if all remaining players are all-in -> run out board.
      if (StreetProgression.shouldRunOutBoard(state)) {
        return _runOutBoard(state);
      }

      // Check if we're at showdown or river is done.
      if (state.street == Street.river) {
        return _completeHand(
          state.copyWith(street: Street.showdown),
          inHand.map((p) => p.index).toList(),
        );
      }

      // Advance to next street.
      var nextState = StreetProgression.advanceStreet(state);
      // After advancing, check if the hand is complete.
      if (nextState.isHandComplete) {
        return _completeHand(
          nextState,
          nextState.activePlayers.map((p) => p.index).toList(),
        );
      }
      return nextState;
    }

    // 3. Advance to the next player.
    final nextPlayer =
        _nextActivePlayer(state.players, state.currentPlayerIndex);
    return state.copyWith(currentPlayerIndex: nextPlayer);
  }

  /// Run out the remaining community cards when no more betting is possible
  /// (all players all-in or only one can act).
  static GameState _runOutBoard(GameState state) {
    var current = state;
    while (current.street != Street.showdown &&
        current.street != Street.river) {
      current = StreetProgression.advanceStreet(current);
    }
    // If we ended at river, advance once more to showdown.
    if (current.street == Street.river) {
      current = StreetProgression.advanceStreet(current);
    }

    final inHand = current.players.where((p) => !p.isFolded).toList();
    return _completeHand(current, inHand.map((p) => p.index).toList());
  }

  /// Mark the hand as complete, compute side pots, and evaluate hands.
  ///
  /// [candidateWinners] are the non-folded player indices. If only one player
  /// remains (everyone else folded), they win without hand evaluation.
  /// If multiple players reach showdown, the hand evaluator determines winners.
  static GameState _completeHand(
      GameState state, List<int> candidateWinners) {
    final sidePots = PotCalculator.calculateSidePots(state.players);

    // Single player remaining (won by fold) — no hand evaluation needed.
    if (candidateWinners.length <= 1) {
      return state.copyWith(
        isHandComplete: true,
        winnerIndices: () => candidateWinners,
        sidePots: sidePots,
      );
    }

    // Multiple players at showdown — evaluate hands.
    final community = state.communityCards;
    final handDescriptions = <int, String>{};

    // Evaluate each non-folded player's hand.
    final minCards = state.gameType == GameType.omaha ? 4 : 2;
    for (final idx in candidateWinners) {
      final player = state.players[idx];
      if (player.holeCards.length >= minCards && community.length >= 3) {
        final evaluated = HandEvaluator.evaluateBest(
          player.holeCards,
          community,
          state.gameType,
        );
        handDescriptions[idx] = evaluated.description;
      }
    }

    // Determine winners per side pot and collect overall winners.
    final overallWinners = <int>{};
    for (final pot in sidePots) {
      final potWinners = HandEvaluator.determineWinners(
        state.players,
        community,
        pot.eligiblePlayerIndices,
        gameType: state.gameType,
      );
      overallWinners.addAll(potWinners);
    }

    // Fallback: if no side pots (shouldn't happen, but safety), use all
    // candidate winners evaluated directly.
    if (overallWinners.isEmpty) {
      final winners = HandEvaluator.determineWinners(
        state.players,
        community,
        candidateWinners,
        gameType: state.gameType,
      );
      overallWinners.addAll(winners);
    }

    return state.copyWith(
      isHandComplete: true,
      winnerIndices: () => overallWinners.toList(),
      sidePots: sidePots,
      handDescriptions: handDescriptions,
    );
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  static void _validateAction(GameState state, PokerAction action) {
    final legal = LegalActionSet.compute(state);

    switch (action.type) {
      case ActionType.fold:
        // Folding is always allowed (even if checking is free, player might
        // want to fold in some UI scenarios). The LegalActionSet says canFold
        // is false when checking is free, but we allow it for flexibility.
        break;
      case ActionType.check:
        if (!legal.canCheck) {
          throw StateError(
            'Player ${action.playerIndex} cannot check; facing a bet of '
            '${state.currentBet}.',
          );
        }
        break;
      case ActionType.call:
        if (legal.callAmount == null) {
          throw StateError(
            'Player ${action.playerIndex} cannot call; no bet to call.',
          );
        }
        break;
      case ActionType.bet:
        if (legal.betRange == null) {
          // Allow all-in bets that are smaller than BB.
          final player = state.players[action.playerIndex];
          if (action.amount != player.stack) {
            throw StateError(
              'Player ${action.playerIndex} cannot bet.',
            );
          }
        } else {
          final range = legal.betRange!;
          if (action.amount < range.min || action.amount > range.max) {
            // Allow if it's an all-in for less.
            final player = state.players[action.playerIndex];
            if (action.amount != player.stack) {
              throw StateError(
                'Bet amount ${action.amount} outside legal range '
                '${range.min}-${range.max}.',
              );
            }
          }
        }
        break;
      case ActionType.raise:
        if (legal.raiseRange == null) {
          // Might be an all-in raise for less than min raise.
          final player = state.players[action.playerIndex];
          final additionalChips = action.amount - player.currentBet;
          if (additionalChips != player.stack) {
            throw StateError(
              'Player ${action.playerIndex} cannot raise.',
            );
          }
        } else {
          final range = legal.raiseRange!;
          if (action.amount < range.min || action.amount > range.max) {
            // Allow all-in raises that don't meet the minimum.
            final player = state.players[action.playerIndex];
            final additionalChips = action.amount - player.currentBet;
            if (additionalChips != player.stack) {
              throw StateError(
                'Raise to ${action.amount} outside legal range '
                '${range.min}-${range.max}.',
              );
            }
          }
        }
        break;
      case ActionType.allIn:
        if (!legal.canAllIn) {
          throw StateError(
            'Player ${action.playerIndex} cannot go all-in (no chips).',
          );
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Find the next active (non-folded, non-all-in) player after [fromIndex].
  static int _nextActivePlayer(List<PlayerState> players, int fromIndex) {
    final n = players.length;
    for (int i = 1; i <= n; i++) {
      final idx = (fromIndex + i) % n;
      if (players[idx].isActive) return idx;
    }
    // Fallback: find any non-folded player.
    for (int i = 1; i <= n; i++) {
      final idx = (fromIndex + i) % n;
      if (!players[idx].isFolded) return idx;
    }
    return fromIndex;
  }

  /// Return a new player list with the given player replaced (matched by
  /// index).
  static List<PlayerState> _updatePlayer(
    List<PlayerState> players,
    PlayerState updated,
  ) {
    return [
      for (final p in players)
        if (p.index == updated.index) updated else p,
    ];
  }
}
