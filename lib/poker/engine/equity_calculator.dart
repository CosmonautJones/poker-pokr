/// Monte Carlo equity calculator for poker hands.
///
/// Estimates win/tie/loss percentages for each player by simulating
/// random board runouts. Supports both Texas Hold'em and Omaha.
///
/// Pure Dart - no Flutter imports.
library;

import 'dart:math';

import '../models/card.dart';
import '../models/game_type.dart';
import '../models/player.dart';
import 'hand_evaluator.dart';

/// Per-player equity result.
class PlayerEquity {
  final int playerIndex;

  /// Win probability (0.0 – 1.0).
  final double winRate;

  /// Tie probability (0.0 – 1.0).
  final double tieRate;

  /// Number of simulations that contributed to this result.
  final int simulations;

  const PlayerEquity({
    required this.playerIndex,
    required this.winRate,
    required this.tieRate,
    required this.simulations,
  });

  /// Combined equity: full credit for wins, split credit for ties.
  double get equity => winRate + tieRate / 2;

  /// Win percentage as an integer (0 – 100).
  int get winPercent => (winRate * 100).round();

  /// Equity percentage as an integer (0 – 100).
  int get equityPercent => (equity * 100).round();

  @override
  String toString() =>
      'PlayerEquity(player $playerIndex: '
      'win=${(winRate * 100).toStringAsFixed(1)}%, '
      'tie=${(tieRate * 100).toStringAsFixed(1)}%, '
      'equity=${(equity * 100).toStringAsFixed(1)}%)';
}

/// Result of an equity calculation for all players in a hand.
class EquityResult {
  final List<PlayerEquity> playerEquities;
  final int totalSimulations;

  const EquityResult({
    required this.playerEquities,
    required this.totalSimulations,
  });

  /// Look up equity for a specific player index.
  PlayerEquity? operator [](int playerIndex) {
    for (final eq in playerEquities) {
      if (eq.playerIndex == playerIndex) return eq;
    }
    return null;
  }
}

class EquityCalculator {
  EquityCalculator._();

  /// Calculate equity for all non-folded players via Monte Carlo simulation.
  ///
  /// [players] – all players (folded players are excluded automatically).
  /// [communityCards] – current board cards (0–5).
  /// [gameType] – determines evaluation rules.
  /// [simulations] – number of random runouts to simulate (default 1000).
  /// [seed] – optional seed for deterministic results (useful in tests).
  static EquityResult calculate({
    required List<PlayerState> players,
    required List<PokerCard> communityCards,
    required GameType gameType,
    int simulations = 1000,
    int? seed,
  }) {
    // Filter to non-folded players with hole cards.
    final minCards = gameType.holeCardCount;
    final activePlayers = players
        .where((p) => !p.isFolded && p.holeCards.length >= minCards)
        .toList();

    // If 0 or 1 player, trivial result.
    if (activePlayers.isEmpty) {
      return const EquityResult(playerEquities: [], totalSimulations: 0);
    }
    if (activePlayers.length == 1) {
      return EquityResult(
        playerEquities: [
          PlayerEquity(
            playerIndex: activePlayers[0].index,
            winRate: 1.0,
            tieRate: 0.0,
            simulations: 0,
          ),
        ],
        totalSimulations: 0,
      );
    }

    // If board is complete (5 cards), just evaluate once — no simulation needed.
    if (communityCards.length == 5) {
      return _evaluateComplete(activePlayers, communityCards, gameType);
    }

    // Build the set of known (dead) cards.
    final deadCards = <int>{};
    for (final card in communityCards) {
      deadCards.add(card.value);
    }
    for (final player in activePlayers) {
      for (final card in player.holeCards) {
        deadCards.add(card.value);
      }
    }

    // Build the remaining deck.
    final remainingDeck = <PokerCard>[
      for (int i = 0; i < 52; i++)
        if (!deadCards.contains(i)) PokerCard(i),
    ];

    final cardsNeeded = 5 - communityCards.length;
    final rng = seed != null ? Random(seed) : Random();

    // Win/tie counters per active player.
    // Tie values are weighted by 2/N (where N = number of tied players) so
    // that the equity formula `winRate + tieRate / 2` yields the correct
    // pot share for multi-way ties.
    final wins = <int, int>{};
    final ties = <int, double>{};
    for (final p in activePlayers) {
      wins[p.index] = 0;
      ties[p.index] = 0;
    }

    for (int sim = 0; sim < simulations; sim++) {
      // Shuffle remaining deck and pick cards for the board.
      _shufflePartial(remainingDeck, cardsNeeded, rng);
      final simBoard = [
        ...communityCards,
        for (int i = 0; i < cardsNeeded; i++)
          remainingDeck[remainingDeck.length - 1 - i],
      ];

      // Evaluate each player's best hand.
      EvaluatedHand? bestHand;
      final hands = <int, EvaluatedHand>{};
      for (final p in activePlayers) {
        final hand = HandEvaluator.evaluateBest(
          p.holeCards,
          simBoard,
          gameType,
        );
        hands[p.index] = hand;
        if (bestHand == null || hand > bestHand) {
          bestHand = hand;
        }
      }

      // Determine winner(s).
      final winnerIndices = <int>[];
      for (final entry in hands.entries) {
        if (entry.value.compareTo(bestHand!) == 0) {
          winnerIndices.add(entry.key);
        }
      }

      if (winnerIndices.length == 1) {
        wins[winnerIndices[0]] = wins[winnerIndices[0]]! + 1;
      } else {
        final weight = 2.0 / winnerIndices.length;
        for (final idx in winnerIndices) {
          ties[idx] = ties[idx]! + weight;
        }
      }
    }

    // Build results.
    final equities = <PlayerEquity>[];
    for (final p in activePlayers) {
      equities.add(PlayerEquity(
        playerIndex: p.index,
        winRate: wins[p.index]! / simulations,
        tieRate: ties[p.index]! / simulations,
        simulations: simulations,
      ));
    }

    return EquityResult(
      playerEquities: equities,
      totalSimulations: simulations,
    );
  }

  /// Evaluate a complete board (no simulation needed).
  static EquityResult _evaluateComplete(
    List<PlayerState> activePlayers,
    List<PokerCard> communityCards,
    GameType gameType,
  ) {
    EvaluatedHand? bestHand;
    final hands = <int, EvaluatedHand>{};
    for (final p in activePlayers) {
      final hand = HandEvaluator.evaluateBest(
        p.holeCards,
        communityCards,
        gameType,
      );
      hands[p.index] = hand;
      if (bestHand == null || hand > bestHand) {
        bestHand = hand;
      }
    }

    final winnerIndices = <int>[];
    for (final entry in hands.entries) {
      if (entry.value.compareTo(bestHand!) == 0) {
        winnerIndices.add(entry.key);
      }
    }

    final isTie = winnerIndices.length > 1;
    final equities = <PlayerEquity>[];
    for (final p in activePlayers) {
      final isWinner = winnerIndices.contains(p.index);
      equities.add(PlayerEquity(
        playerIndex: p.index,
        winRate: isWinner && !isTie ? 1.0 : 0.0,
        tieRate: isWinner && isTie ? 2.0 / winnerIndices.length : 0.0,
        simulations: 1,
      ));
    }

    return EquityResult(
      playerEquities: equities,
      totalSimulations: 1,
    );
  }

  /// Fisher-Yates partial shuffle: randomizes the last [count] elements
  /// of the deck for efficient sampling without copying.
  static void _shufflePartial(List<PokerCard> deck, int count, Random rng) {
    final n = deck.length;
    for (int i = 0; i < count; i++) {
      final swapIdx = n - 1 - i;
      final j = rng.nextInt(swapIdx + 1);
      if (j != swapIdx) {
        final tmp = deck[swapIdx];
        deck[swapIdx] = deck[j];
        deck[j] = tmp;
      }
    }
  }
}
