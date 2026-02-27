/// Computes the set of legal actions for the current player.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/game_state.dart';
import '../models/game_type.dart';

class LegalActionSet {
  final bool canFold;
  final bool canCheck;
  final double? callAmount;
  final ({double min, double max})? betRange;
  final ({double min, double max})? raiseRange;
  final bool canAllIn;
  final double? allInAmount;

  const LegalActionSet({
    this.canFold = false,
    this.canCheck = false,
    this.callAmount,
    this.betRange,
    this.raiseRange,
    this.canAllIn = false,
    this.allInAmount,
  });

  /// Compute the legal actions for the player whose turn it is.
  ///
  /// Follows No-Limit rules for Hold'em, Pot-Limit rules for Omaha:
  ///   - Min bet = big blind
  ///   - Min raise = current bet + last raise size (at least BB)
  ///   - Pot-limit: max bet = pot, max raise-to = tableBet + (pot + toCall)
  ///   - All-in is always available if the player has chips
  static LegalActionSet compute(GameState state) {
    if (state.isHandComplete) {
      return const LegalActionSet();
    }

    final player = state.players[state.currentPlayerIndex];
    final stack = player.stack;
    final playerBet = player.currentBet;
    final tableBet = state.currentBet;
    final bb = state.bigBlind;
    final lastRaise = state.lastRaiseSize > 0 ? state.lastRaiseSize : bb;

    // Player has no chips - nothing to do.
    if (stack <= 0) {
      return const LegalActionSet();
    }

    final toCall = tableBet - playerBet;
    final bool facingBet = toCall > 0;

    // --- Fold ---
    // Can fold whenever facing a bet (no point folding if checking is free).
    final bool canFold = facingBet;

    // --- Check ---
    // Can check only when not facing a bet.
    final bool canCheck = !facingBet;

    // --- Call ---
    double? callAmount;
    if (facingBet) {
      // Call amount is capped at the player's remaining stack.
      callAmount = toCall < stack ? toCall : stack;
    }

    // --- Bet (opening bet, no current bet on this street) ---
    ({double min, double max})? betRange;
    if (!facingBet) {
      final minBet = bb;
      // Must have more than the minimum to make a non-all-in bet.
      if (stack > minBet) {
        betRange = (min: minBet, max: stack);
      }
      // If stack <= minBet, the only option besides check is all-in.
    }

    // --- Raise (there is already a bet to raise over) ---
    ({double min, double max})? raiseRange;
    if (facingBet) {
      // Min raise total = currentBet + lastRaiseSize.
      final minRaiseTotal = tableBet + lastRaise;
      // The amount the player must PUT IN for a min raise.
      final minRaiseAmount = minRaiseTotal - playerBet;
      // Must have more chips than the call amount AND enough for at least the
      // min raise to have a non-all-in raise available.
      if (stack > toCall && stack >= minRaiseAmount) {
        raiseRange = (min: minRaiseTotal, max: playerBet + stack);
      }
      // If stack > toCall but < minRaiseAmount, the player can still all-in
      // (handled below), but cannot make a legal raise.
    }

    // --- Pot-limit cap (Omaha is always pot-limit) ---
    if (state.gameType == GameType.omaha) {
      if (betRange != null) {
        // Opening bet: max = current pot size, capped at stack.
        final potMax = state.pot.clamp(betRange.min, stack);
        if (potMax >= betRange.min) {
          betRange = (min: betRange.min, max: potMax);
        } else {
          betRange = null; // Can't make a legal bet; only all-in.
        }
      }
      if (raiseRange != null) {
        // Pot-limit raise: player calls first (pot grows by toCall),
        // then may raise up to the new pot size.
        //   potAfterCall = pot + toCall
        //   maxRaiseTo   = tableBet + potAfterCall
        final potAfterCall = state.pot + toCall;
        final maxRaiseTo =
            (tableBet + potAfterCall).clamp(raiseRange.min, playerBet + stack);
        if (maxRaiseTo >= raiseRange.min) {
          raiseRange = (min: raiseRange.min, max: maxRaiseTo);
        } else {
          raiseRange = null;
        }
      }
    }

    // --- All-in ---
    // Always available if the player has chips.
    final bool canAllIn = stack > 0;
    final double? allInAmount = canAllIn ? stack : null;

    return LegalActionSet(
      canFold: canFold,
      canCheck: canCheck,
      callAmount: callAmount,
      betRange: betRange,
      raiseRange: raiseRange,
      canAllIn: canAllIn,
      allInAmount: allInAmount,
    );
  }

  @override
  String toString() =>
      'LegalActionSet(fold: $canFold, check: $canCheck, '
      'call: $callAmount, bet: $betRange, raise: $raiseRange, '
      'allIn: $canAllIn/$allInAmount)';
}
