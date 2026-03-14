/// Selects random poker actions from the legal action set.
///
/// Pure Dart - no Flutter imports.
library;

import 'dart:math';

import '../models/action.dart';
import '../models/game_state.dart';
import 'legal_actions.dart';

class RandomActionSelector {
  /// Select a random legal action for the current player.
  ///
  /// Uses weighted probabilities to produce realistic play:
  ///   - Check: 35%  |  Call: 30%  |  Bet: 15%  |  Raise: 15%
  ///   - All-in: 5%  |  Fold: 15% (only when facing a bet)
  ///
  /// Bet/raise amounts are chosen from common poker sizings
  /// (1/3, 1/2, 2/3, pot) clamped to legal ranges.
  static PokerAction selectAction(GameState state, {Random? random}) {
    final rng = random ?? Random();
    final legal = LegalActionSet.compute(state);
    final playerIndex = state.currentPlayerIndex;

    // Build weighted options.
    final options = <_WeightedAction>[];

    if (legal.canCheck) {
      options.add(_WeightedAction(35, () => PokerAction(
        playerIndex: playerIndex,
        type: ActionType.check,
      )));
    }

    if (legal.canFold) {
      options.add(_WeightedAction(15, () => PokerAction(
        playerIndex: playerIndex,
        type: ActionType.fold,
      )));
    }

    if (legal.callAmount != null) {
      options.add(_WeightedAction(30, () => PokerAction(
        playerIndex: playerIndex,
        type: ActionType.call,
        amount: legal.callAmount!,
      )));
    }

    if (legal.betRange != null) {
      options.add(_WeightedAction(15, () {
        final amount = _pickSizing(
          legal.betRange!.min,
          legal.betRange!.max,
          state.pot,
          rng,
        );
        return PokerAction(
          playerIndex: playerIndex,
          type: ActionType.bet,
          amount: amount,
        );
      }));
    }

    if (legal.raiseRange != null) {
      options.add(_WeightedAction(15, () {
        final amount = _pickSizing(
          legal.raiseRange!.min,
          legal.raiseRange!.max,
          state.pot,
          rng,
        );
        return PokerAction(
          playerIndex: playerIndex,
          type: ActionType.raise,
          amount: amount,
        );
      }));
    }

    if (legal.canAllIn && legal.allInAmount != null) {
      options.add(_WeightedAction(5, () => PokerAction(
        playerIndex: playerIndex,
        type: ActionType.allIn,
        amount: legal.allInAmount!,
      )));
    }

    // Should never happen, but just in case.
    if (options.isEmpty) {
      throw StateError('No legal actions available for player $playerIndex');
    }

    // Weighted random selection.
    final totalWeight = options.fold<int>(0, (sum, o) => sum + o.weight);
    var roll = rng.nextInt(totalWeight);
    for (final option in options) {
      roll -= option.weight;
      if (roll < 0) return option.build();
    }
    return options.last.build();
  }

  /// Pick a bet/raise amount from common poker sizings.
  static double _pickSizing(
    double min,
    double max,
    double pot,
    Random rng,
  ) {
    if (min >= max) return min;

    // Common sizings as fractions of pot.
    final sizings = <double>[
      pot * 1 / 3,
      pot * 1 / 2,
      pot * 2 / 3,
      pot,
    ];

    // Filter to legal range and deduplicate.
    final legal = sizings
        .where((s) => s >= min && s <= max)
        .toList();

    if (legal.isNotEmpty) {
      return legal[rng.nextInt(legal.length)];
    }

    // No standard sizing fits: pick random within range.
    // Round to nearest 0.5 to avoid weird amounts.
    final range = max - min;
    final raw = min + rng.nextDouble() * range;
    return (raw * 2).roundToDouble() / 2;
  }
}

class _WeightedAction {
  final int weight;
  final PokerAction Function() build;

  const _WeightedAction(this.weight, this.build);
}
