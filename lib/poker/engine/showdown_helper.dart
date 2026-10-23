/// Tiny convenience over [HandEvaluator] that knows how to interpret a
/// [GameState] for a given seat. Used by the UI for the showdown banner
/// and by progression for achievement evaluation.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/game_state.dart';
import '../models/game_type.dart';
import 'hand_evaluator.dart';

/// Returns the best hand for [seat] given the current state, or null when
/// it cannot be evaluated (folded, hole cards missing, or fewer than 3
/// community cards on board).
EvaluatedHand? evaluateSeatHand(GameState gs, int seat) {
  if (seat < 0 || seat >= gs.players.length) return null;
  final p = gs.players[seat];
  if (p.isFolded) return null;
  final minHole = gs.gameType == GameType.omaha ? 4 : 2;
  if (p.holeCards.length < minHole) return null;
  if (gs.communityCards.length < 3) return null;
  return HandEvaluator.evaluateBest(
    p.holeCards,
    gs.communityCards,
    gs.gameType,
  );
}
