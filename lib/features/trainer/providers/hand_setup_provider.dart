import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Notifier that manages the create-hand form state.
class HandSetupNotifier extends Notifier<HandSetup> {
  @override
  HandSetup build() => HandSetup.defaults(playerCount: 6);

  void setPlayerCount(int count) {
    final current = state;
    // Adjust names and stacks lists to match new count.
    final names = List.generate(count, (i) {
      if (i < current.playerNames.length) return current.playerNames[i];
      return 'Player ${i + 1}';
    });
    final stacks = List.generate(count, (i) {
      if (i < current.stacks.length) return current.stacks[i];
      return current.bigBlind * 100;
    });
    // Adjust hole cards list.
    final oldHoleCards = current.holeCards;
    final holeCards = List<List<PokerCard>?>.generate(count, (i) {
      if (oldHoleCards != null && i < oldHoleCards.length) {
        return oldHoleCards[i];
      }
      return null;
    });
    // Clamp dealer index if needed.
    final dealer =
        current.dealerIndex >= count ? 0 : current.dealerIndex;
    state = current.copyWith(
      playerCount: count,
      playerNames: names,
      stacks: stacks,
      dealerIndex: dealer,
      holeCards: holeCards,
    );
  }

  void setSmallBlind(double sb) {
    state = state.copyWith(smallBlind: sb);
  }

  void setBigBlind(double bb) {
    state = state.copyWith(bigBlind: bb);
  }

  void setAnte(double ante) {
    state = state.copyWith(ante: ante);
  }

  void setDealerIndex(int index) {
    state = state.copyWith(dealerIndex: index);
  }

  void setGameType(GameType gameType) {
    // Clear hole cards when switching game types (different card count).
    if (gameType != state.gameType) {
      state = state.copyWith(
        gameType: gameType,
        holeCards: List<List<PokerCard>?>.filled(state.playerCount, null),
      );
    }
  }

  void setStraddleEnabled(bool enabled) {
    state = state.copyWith(straddleEnabled: enabled);
  }

  void setStraddleMultiplier(double multiplier) {
    state = state.copyWith(straddleMultiplier: multiplier);
  }

  void setPlayerName(int index, String name) {
    final names = List<String>.of(state.playerNames);
    names[index] = name;
    state = state.copyWith(playerNames: names);
  }

  void setPlayerStack(int index, double stack) {
    final stacks = List<double>.of(state.stacks);
    stacks[index] = stack;
    state = state.copyWith(stacks: stacks);
  }

  /// Set a specific hole card for a player.
  /// [cardIndex] can be 0-3 depending on game type.
  void setPlayerHoleCard(int playerIndex, int cardIndex, PokerCard card) {
    final holeCards = _ensureHoleCards();
    final playerCards = List<PokerCard?>.of(holeCards[playerIndex] ?? []);
    // Pad with null placeholders if needed.
    while (playerCards.length <= cardIndex) {
      playerCards.add(null);
    }
    playerCards[cardIndex] = card;
    // Filter out null placeholders for storage.
    holeCards[playerIndex] =
        playerCards.whereType<PokerCard>().toList();
    state = state.copyWith(holeCards: holeCards);
  }

  /// Clear a specific hole card for a player.
  void clearPlayerHoleCard(int playerIndex, int cardIndex) {
    final holeCards = _ensureHoleCards();
    final playerCards = holeCards[playerIndex];
    if (playerCards == null || cardIndex >= playerCards.length) return;
    final updated = List<PokerCard>.of(playerCards);
    updated.removeAt(cardIndex);
    holeCards[playerIndex] = updated.isEmpty ? null : updated;
    state = state.copyWith(holeCards: holeCards);
  }

  /// Clear all hole cards for a player.
  void clearPlayerHoleCards(int playerIndex) {
    final holeCards = _ensureHoleCards();
    holeCards[playerIndex] = null;
    state = state.copyWith(holeCards: holeCards);
  }

  /// Deal random hole cards to a player, avoiding cards already assigned.
  void dealRandomHoleCards(int playerIndex) {
    final holeCards = _ensureHoleCards();
    final usedCards = <int>{};
    for (int i = 0; i < holeCards.length; i++) {
      if (i != playerIndex && holeCards[i] != null) {
        for (final c in holeCards[i]!) {
          usedCards.add(c.value);
        }
      }
    }
    final available = <PokerCard>[];
    for (int v = 0; v < 52; v++) {
      if (!usedCards.contains(v)) available.add(PokerCard(v));
    }
    available.shuffle(Random());
    final cardCount = state.gameType.holeCardCount;
    holeCards[playerIndex] = available.sublist(0, cardCount);
    state = state.copyWith(holeCards: holeCards);
  }

  /// Get all cards currently assigned to other players (for filtering pickers).
  Set<int> usedCardValues([int? excludePlayer]) {
    final used = <int>{};
    final holeCards = state.holeCards;
    if (holeCards == null) return used;
    for (int i = 0; i < holeCards.length; i++) {
      if (i == excludePlayer) continue;
      if (holeCards[i] != null) {
        for (final c in holeCards[i]!) {
          used.add(c.value);
        }
      }
    }
    return used;
  }

  List<List<PokerCard>?> _ensureHoleCards() {
    final existing = state.holeCards;
    if (existing != null) return List<List<PokerCard>?>.of(existing);
    return List<List<PokerCard>?>.filled(state.playerCount, null);
  }
}

final handSetupProvider =
    NotifierProvider<HandSetupNotifier, HandSetup>(HandSetupNotifier.new);

/// Holds the active HandSetup for a new hand being played.
/// null means no active new hand (i.e. loading a saved hand instead).
final activeHandSetupProvider = StateProvider<HandSetup?>((ref) => null);
