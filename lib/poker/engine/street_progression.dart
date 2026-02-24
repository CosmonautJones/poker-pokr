/// Street progression logic: determines when betting rounds are complete and
/// advances the hand to the next street.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/card.dart';
import '../models/game_state.dart';
import '../models/player.dart';
import '../models/street.dart';

class StreetProgression {
  /// Whether the current betting round is complete.
  ///
  /// A betting round is complete when:
  ///   1. All active (non-folded, non-all-in) players have acted at least once
  ///      this street, AND
  ///   2. All non-folded players' current bets are matched (or they are
  ///      all-in).
  ///
  /// Special case: if only 0 or 1 active non-all-in players remain, the round
  /// is automatically complete (nothing left to decide).
  static bool isBettingRoundComplete(GameState state) {
    final activeNonAllIn = state.activeNonAllInPlayers;

    // No one (or one person) left to act -> done.
    if (activeNonAllIn.length <= 1) {
      return true;
    }

    // All active non-all-in players must have acted this street.
    if (state.playersActedThisStreet < activeNonAllIn.length) {
      return false;
    }

    // All non-folded players' bets must be matched (or they are all-in).
    final targetBet = state.currentBet;
    for (final p in state.players) {
      if (p.isFolded) continue;
      if (p.isAllIn) continue;
      if (p.currentBet != targetBet) return false;
    }

    return true;
  }

  /// Advance the game state to the next street.
  ///
  /// Deals community cards (3 for flop, 1 for turn/river), resets per-street
  /// player bets, and sets the current player to the first active player after
  /// the dealer.
  static GameState advanceStreet(GameState state) {
    final nextStreet = state.street.next;
    final deck = state.deck;
    final community = List<PokerCard>.of(state.communityCards);

    // Deal community cards for the new street.
    switch (nextStreet) {
      case Street.flop:
        // Burn one, deal three.
        deck.deal(); // burn
        community.addAll(deck.dealMany(3));
        break;
      case Street.turn:
      case Street.river:
        // Burn one, deal one.
        deck.deal(); // burn
        community.add(deck.deal());
        break;
      case Street.preflop:
      case Street.showdown:
        // No cards dealt.
        break;
    }

    // Reset per-street state for each player.
    final updatedPlayers = state.players
        .map((p) => p.copyWith(currentBet: 0))
        .toList();

    // Find the first active (non-folded, non-all-in) player after the dealer.
    final nextPlayer =
        _firstActivePlayerAfter(updatedPlayers, state.dealerIndex);

    final isComplete = nextStreet == Street.showdown ||
        _countInHand(updatedPlayers) <= 1;

    return state.copyWith(
      street: nextStreet,
      communityCards: community,
      deck: deck,
      players: updatedPlayers,
      currentBet: 0,
      lastRaiseSize: 0,
      lastAggressorIndex: () => null,
      currentPlayerIndex: nextPlayer,
      playersActedThisStreet: 0,
      streetStartActionIndex: state.actionHistory.length,
      isHandComplete: isComplete,
    );
  }

  /// Whether the hand is complete.
  ///
  /// A hand is complete if:
  ///   - Only one non-folded player remains, OR
  ///   - We have reached showdown, OR
  ///   - All remaining players are all-in (and streets have been run out), OR
  ///   - The river betting round is complete.
  static bool isHandComplete(GameState state) {
    // Only one player left in the hand.
    if (_countInHand(state.players) <= 1) return true;

    // Showdown reached.
    if (state.street == Street.showdown) return true;

    // River betting complete.
    if (state.street == Street.river && isBettingRoundComplete(state)) {
      return true;
    }

    return false;
  }

  /// Checks whether all remaining players are all-in (or only one non-all-in
  /// player remains, making further betting impossible). In this case the hand
  /// should run out the remaining community cards without further action.
  static bool shouldRunOutBoard(GameState state) {
    final inHand = state.players.where((p) => !p.isFolded).toList();
    if (inHand.length <= 1) return false; // hand is already over
    final canAct = inHand.where((p) => !p.isAllIn).length;
    return canAct <= 1;
  }

  // ---- Helpers ----

  /// Returns the seat index of the first active (non-folded, non-all-in)
  /// player after [fromIndex], wrapping around the table. If none found,
  /// returns [fromIndex] (or 0 as fallback).
  static int _firstActivePlayerAfter(List<PlayerState> players, int fromIndex) {
    final n = players.length;
    for (int i = 1; i <= n; i++) {
      final idx = (fromIndex + i) % n;
      if (players[idx].isActive) return idx;
    }
    // No active player found - return first non-folded player (edge case:
    // everyone all-in except maybe one).
    for (int i = 1; i <= n; i++) {
      final idx = (fromIndex + i) % n;
      if (!players[idx].isFolded) return idx;
    }
    return 0;
  }

  /// Count players who have not folded.
  static int _countInHand(List<PlayerState> players) =>
      players.where((p) => !p.isFolded).length;
}
