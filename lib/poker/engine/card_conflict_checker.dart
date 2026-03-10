/// Utility for detecting card conflicts across players and community cards.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/game_state.dart';

class CardConflictChecker {
  /// Returns the set of card values currently in use (hole cards + community),
  /// optionally excluding the specified player's hole cards.
  static Set<int> usedCardValues(
    GameState state, {
    int? excludePlayerIndex,
  }) {
    final used = <int>{};
    for (final player in state.players) {
      if (player.index == excludePlayerIndex) continue;
      for (final card in player.holeCards) {
        used.add(card.value);
      }
    }
    for (final card in state.communityCards) {
      used.add(card.value);
    }
    return used;
  }

  /// Check if any card value appears more than once across all players'
  /// hole cards and community cards.
  ///
  /// Returns the list of duplicate card values, or empty if no conflicts.
  static List<int> findConflicts(GameState state) {
    final seen = <int>{};
    final duplicates = <int>[];
    for (final player in state.players) {
      for (final card in player.holeCards) {
        if (!seen.add(card.value)) duplicates.add(card.value);
      }
    }
    for (final card in state.communityCards) {
      if (!seen.add(card.value)) duplicates.add(card.value);
    }
    return duplicates;
  }
}
