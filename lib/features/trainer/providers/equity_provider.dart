import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/poker/engine/equity_calculator.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

/// Computes equity on demand for a given game state.
///
/// Uses a family provider keyed by an [_EquityKey] so the result is
/// cached per unique (community cards, active hole cards, game type) tuple.
/// The computation runs asynchronously to avoid blocking the UI.
class _EquityKey {
  final GameState gameState;

  _EquityKey(this.gameState);

  /// Identity based on the cards that affect equity, not the full game state.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _EquityKey) return false;
    final gs = gameState;
    final ogs = other.gameState;
    if (gs.gameType != ogs.gameType) return false;
    if (gs.communityCards.length != ogs.communityCards.length) return false;
    for (int i = 0; i < gs.communityCards.length; i++) {
      if (gs.communityCards[i] != ogs.communityCards[i]) return false;
    }
    // Compare active (non-folded) players' hole cards.
    final active = gs.players.where((p) => !p.isFolded).toList();
    final otherActive = ogs.players.where((p) => !p.isFolded).toList();
    if (active.length != otherActive.length) return false;
    for (int i = 0; i < active.length; i++) {
      if (active[i].index != otherActive[i].index) return false;
      if (active[i].holeCards.length != otherActive[i].holeCards.length) {
        return false;
      }
      for (int j = 0; j < active[i].holeCards.length; j++) {
        if (active[i].holeCards[j] != otherActive[i].holeCards[j]) return false;
      }
    }
    return true;
  }

  @override
  int get hashCode {
    final gs = gameState;
    var hash = gs.gameType.hashCode;
    for (final c in gs.communityCards) {
      hash = Object.hash(hash, c.value);
    }
    for (final p in gs.players.where((p) => !p.isFolded)) {
      hash = Object.hash(hash, p.index);
      for (final c in p.holeCards) {
        hash = Object.hash(hash, c.value);
      }
    }
    return hash;
  }
}

/// Provides equity calculation results for a game state.
///
/// Returns null while computing or if there's nothing to compute.
final equityProvider =
    AutoDisposeFutureProviderFamily<EquityResult?, GameState>(
  (ref, gameState) async {
    // Don't compute if hand is complete or only 1 player left.
    final activePlayers = gameState.players.where((p) => !p.isFolded).toList();
    if (gameState.isHandComplete || activePlayers.length < 2) {
      return null;
    }

    // Don't compute if any active player has no hole cards.
    final minCards = gameState.gameType.holeCardCount;
    if (activePlayers.any((p) => p.holeCards.length < minCards)) {
      return null;
    }

    // Small delay to debounce rapid state changes.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Run the Monte Carlo simulation.
    // 2000 simulations gives ~2% margin of error — fast enough on mobile.
    return EquityCalculator.calculate(
      players: gameState.players,
      communityCards: gameState.communityCards,
      gameType: gameState.gameType,
      simulations: 2000,
    );
  },
);
