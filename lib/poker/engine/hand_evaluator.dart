/// Poker hand evaluation: ranks 5-card hands and selects the best 5 from 7.
///
/// Pure Dart - no Flutter imports.
library;

import '../models/card.dart';
import '../models/game_type.dart';
import '../models/player.dart';

// ---------------------------------------------------------------------------
// Hand ranking categories (higher = better)
// ---------------------------------------------------------------------------

enum HandRank {
  highCard,
  pair,
  twoPair,
  threeOfAKind,
  straight,
  flush,
  fullHouse,
  fourOfAKind,
  straightFlush;

  String get displayName => switch (this) {
        HandRank.highCard => 'High Card',
        HandRank.pair => 'Pair',
        HandRank.twoPair => 'Two Pair',
        HandRank.threeOfAKind => 'Three of a Kind',
        HandRank.straight => 'Straight',
        HandRank.flush => 'Flush',
        HandRank.fullHouse => 'Full House',
        HandRank.fourOfAKind => 'Four of a Kind',
        HandRank.straightFlush => 'Straight Flush',
      };
}

// ---------------------------------------------------------------------------
// Evaluated hand — a comparable hand result
// ---------------------------------------------------------------------------

/// The result of evaluating a poker hand.
///
/// [rank] is the hand category (pair, flush, etc.).
/// [values] is a list of tiebreaker values in descending priority.
/// [cards] are the 5 cards that form the best hand.
/// [description] is a human-readable string like "Pair of Kings".
class EvaluatedHand implements Comparable<EvaluatedHand> {
  final HandRank rank;
  final List<int> values;
  final List<PokerCard> cards;
  final String description;

  const EvaluatedHand({
    required this.rank,
    required this.values,
    required this.cards,
    required this.description,
  });

  @override
  int compareTo(EvaluatedHand other) {
    // Compare rank first.
    final rankCmp = rank.index.compareTo(other.rank.index);
    if (rankCmp != 0) return rankCmp;

    // Compare tiebreaker values.
    for (int i = 0; i < values.length && i < other.values.length; i++) {
      final cmp = values[i].compareTo(other.values[i]);
      if (cmp != 0) return cmp;
    }
    return 0;
  }

  bool operator >(EvaluatedHand other) => compareTo(other) > 0;
  bool operator <(EvaluatedHand other) => compareTo(other) < 0;
  bool operator >=(EvaluatedHand other) => compareTo(other) >= 0;
  bool operator <=(EvaluatedHand other) => compareTo(other) <= 0;

  @override
  String toString() => 'EvaluatedHand($description, rank: $rank)';
}

// ---------------------------------------------------------------------------
// Hand Evaluator
// ---------------------------------------------------------------------------

class HandEvaluator {
  HandEvaluator._();

  /// Evaluate the best 5-card hand from a player's 2 hole cards + community.
  ///
  /// [holeCards] must have exactly 2 cards.
  /// [communityCards] must have 3-5 cards.
  /// Returns the best [EvaluatedHand] from all C(n,5) combinations.
  static EvaluatedHand evaluateBestHand(
    List<PokerCard> holeCards,
    List<PokerCard> communityCards,
  ) {
    final allCards = [...holeCards, ...communityCards];
    assert(allCards.length >= 5 && allCards.length <= 7);

    if (allCards.length == 5) {
      return evaluate5(allCards);
    }

    // Try all C(n, 5) combinations and keep the best.
    EvaluatedHand? best;
    final combos = _combinations(allCards, 5);
    for (final combo in combos) {
      final hand = evaluate5(combo);
      if (best == null || hand > best) {
        best = hand;
      }
    }
    return best!;
  }

  /// Evaluate the best 5-card hand for Omaha: must use exactly 2 hole cards
  /// and exactly 3 community cards.
  ///
  /// [holeCards] must have exactly 4 cards.
  /// [communityCards] must have 3-5 cards.
  static EvaluatedHand evaluateBestHandOmaha(
    List<PokerCard> holeCards,
    List<PokerCard> communityCards,
  ) {
    assert(holeCards.length == 4);
    assert(communityCards.length >= 3 && communityCards.length <= 5);

    EvaluatedHand? best;
    // C(4,2) = 6 hole card pairs × C(community, 3) community triples.
    for (final holePair in _combinations(holeCards, 2)) {
      for (final communityTriple in _combinations(communityCards, 3)) {
        final hand = evaluate5([...holePair, ...communityTriple]);
        if (best == null || hand > best) {
          best = hand;
        }
      }
    }
    return best!;
  }

  /// Game-type-aware dispatcher: evaluates the best hand using the correct
  /// rules for the given [gameType].
  static EvaluatedHand evaluateBest(
    List<PokerCard> holeCards,
    List<PokerCard> communityCards,
    GameType gameType,
  ) {
    return gameType == GameType.omaha
        ? evaluateBestHandOmaha(holeCards, communityCards)
        : evaluateBestHand(holeCards, communityCards);
  }

  /// Evaluate exactly 5 cards as a poker hand.
  static EvaluatedHand evaluate5(List<PokerCard> cards) {
    assert(cards.length == 5);

    final ranks = cards.map((c) => c.rank.value).toList()..sort();
    final suits = cards.map((c) => c.suit).toList();

    final isFlush = suits.every((s) => s == suits.first);
    final isStraight = _isStraight(ranks);

    // Check for ace-low straight (wheel): A-2-3-4-5.
    final isWheel = _isWheel(ranks);
    final straightHigh =
        isWheel ? 5 : (isStraight ? ranks.last : 0);

    // Count rank occurrences.
    final counts = <int, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }

    // Sort groups by (count descending, rank descending).
    final groups = counts.entries.toList()
      ..sort((a, b) {
        final countCmp = b.value.compareTo(a.value);
        if (countCmp != 0) return countCmp;
        return b.key.compareTo(a.key);
      });

    // --- Straight flush (includes royal flush) ---
    if (isFlush && (isStraight || isWheel)) {
      final high = straightHigh;
      final desc = high == 14
          ? 'Royal Flush'
          : 'Straight Flush, ${_rankName(high)} high';
      return EvaluatedHand(
        rank: HandRank.straightFlush,
        values: [high],
        cards: cards,
        description: desc,
      );
    }

    // --- Four of a kind ---
    if (groups[0].value == 4) {
      final quadRank = groups[0].key;
      final kicker = groups[1].key;
      return EvaluatedHand(
        rank: HandRank.fourOfAKind,
        values: [quadRank, kicker],
        cards: cards,
        description: 'Four of a Kind, ${_rankName(quadRank)}s',
      );
    }

    // --- Full house ---
    if (groups[0].value == 3 && groups[1].value == 2) {
      final tripRank = groups[0].key;
      final pairRank = groups[1].key;
      return EvaluatedHand(
        rank: HandRank.fullHouse,
        values: [tripRank, pairRank],
        cards: cards,
        description:
            '${_rankName(tripRank)}s full of ${_rankName(pairRank)}s',
      );
    }

    // --- Flush ---
    if (isFlush) {
      final sorted = ranks.reversed.toList();
      return EvaluatedHand(
        rank: HandRank.flush,
        values: sorted,
        cards: cards,
        description: 'Flush, ${_rankName(sorted[0])} high',
      );
    }

    // --- Straight ---
    if (isStraight || isWheel) {
      return EvaluatedHand(
        rank: HandRank.straight,
        values: [straightHigh],
        cards: cards,
        description: 'Straight, ${_rankName(straightHigh)} high',
      );
    }

    // --- Three of a kind ---
    if (groups[0].value == 3) {
      final tripRank = groups[0].key;
      final kickers = groups
          .where((g) => g.value == 1)
          .map((g) => g.key)
          .toList()
        ..sort((a, b) => b.compareTo(a));
      return EvaluatedHand(
        rank: HandRank.threeOfAKind,
        values: [tripRank, ...kickers],
        cards: cards,
        description: 'Three of a Kind, ${_rankName(tripRank)}s',
      );
    }

    // --- Two pair ---
    if (groups[0].value == 2 && groups[1].value == 2) {
      final highPair =
          groups[0].key > groups[1].key ? groups[0].key : groups[1].key;
      final lowPair =
          groups[0].key > groups[1].key ? groups[1].key : groups[0].key;
      final kicker =
          groups.firstWhere((g) => g.value == 1).key;
      return EvaluatedHand(
        rank: HandRank.twoPair,
        values: [highPair, lowPair, kicker],
        cards: cards,
        description:
            'Two Pair, ${_rankName(highPair)}s and ${_rankName(lowPair)}s',
      );
    }

    // --- Pair ---
    if (groups[0].value == 2) {
      final pairRank = groups[0].key;
      final kickers = groups
          .where((g) => g.value == 1)
          .map((g) => g.key)
          .toList()
        ..sort((a, b) => b.compareTo(a));
      return EvaluatedHand(
        rank: HandRank.pair,
        values: [pairRank, ...kickers],
        cards: cards,
        description: 'Pair of ${_rankName(pairRank)}s',
      );
    }

    // --- High card ---
    final sorted = ranks.reversed.toList();
    return EvaluatedHand(
      rank: HandRank.highCard,
      values: sorted,
      cards: cards,
      description: '${_rankName(sorted[0])} High',
    );
  }

  // -----------------------------------------------------------------------
  // Showdown: determine winner(s) for each pot
  // -----------------------------------------------------------------------

  /// Determine the winners for a set of eligible player indices.
  ///
  /// Returns the indices of the winning player(s) (ties are possible).
  static List<int> determineWinners(
    List<PlayerState> players,
    List<PokerCard> communityCards,
    List<int> eligibleIndices, {
    GameType gameType = GameType.texasHoldem,
  }) {
    if (eligibleIndices.length <= 1) return eligibleIndices;

    // Need at least 3 community cards for hand evaluation.
    // If fewer (e.g. preflop all-in before runout), return all eligible.
    if (communityCards.length < 3) return eligibleIndices;

    final minCards = gameType == GameType.omaha ? 4 : 2;

    // Evaluate each eligible player's hand.
    final evaluations = <int, EvaluatedHand>{};
    for (final idx in eligibleIndices) {
      final player = players[idx];
      if (player.holeCards.length < minCards) continue;
      evaluations[idx] =
          evaluateBest(player.holeCards, communityCards, gameType);
    }

    if (evaluations.isEmpty) return eligibleIndices;

    // Find the best hand.
    EvaluatedHand? best;
    for (final hand in evaluations.values) {
      if (best == null || hand > best) best = hand;
    }

    // Collect all players who tie for the best hand.
    final winners = <int>[];
    for (final entry in evaluations.entries) {
      if (entry.value.compareTo(best!) == 0) {
        winners.add(entry.key);
      }
    }

    return winners;
  }

  /// Full showdown: awards each side pot to its winner(s).
  ///
  /// Returns a [ShowdownResult] with per-player hand evaluations and pot awards.
  static ShowdownResult showdown({
    required List<PlayerState> players,
    required List<PokerCard> communityCards,
    required List<SidePotInfo> sidePots,
    GameType gameType = GameType.texasHoldem,
  }) {
    final evaluations = <int, EvaluatedHand>{};
    final awards = <int, double>{};

    final minCards = gameType == GameType.omaha ? 4 : 2;

    // Evaluate all non-folded players who have hole cards.
    for (final p in players) {
      if (p.isFolded || p.holeCards.length < minCards) continue;
      if (communityCards.length >= 3) {
        evaluations[p.index] =
            evaluateBest(p.holeCards, communityCards, gameType);
      }
    }

    // Award each pot.
    for (final pot in sidePots) {
      final eligible = pot.eligiblePlayerIndices;
      final winners = determineWinners(
        players,
        communityCards,
        eligible,
        gameType: gameType,
      );

      if (winners.isEmpty) continue;

      final share = pot.amount / winners.length;
      for (final w in winners) {
        awards[w] = (awards[w] ?? 0) + share;
      }
    }

    return ShowdownResult(
      evaluations: evaluations,
      awards: awards,
    );
  }

  // -----------------------------------------------------------------------
  // Helpers
  // -----------------------------------------------------------------------

  static bool _isStraight(List<int> sortedRanks) {
    for (int i = 1; i < sortedRanks.length; i++) {
      if (sortedRanks[i] != sortedRanks[i - 1] + 1) return false;
    }
    return true;
  }

  /// Check for ace-low straight (wheel): A-2-3-4-5.
  /// In sorted order: [2, 3, 4, 5, 14].
  static bool _isWheel(List<int> sortedRanks) {
    return sortedRanks.length == 5 &&
        sortedRanks[0] == 2 &&
        sortedRanks[1] == 3 &&
        sortedRanks[2] == 4 &&
        sortedRanks[3] == 5 &&
        sortedRanks[4] == 14;
  }

  static String _rankName(int value) => switch (value) {
        2 => 'Two',
        3 => 'Three',
        4 => 'Four',
        5 => 'Five',
        6 => 'Six',
        7 => 'Seven',
        8 => 'Eight',
        9 => 'Nine',
        10 => 'Ten',
        11 => 'Jack',
        12 => 'Queen',
        13 => 'King',
        14 => 'Ace',
        _ => '$value',
      };

  /// Generate all C(n, k) combinations of a list.
  static List<List<T>> _combinations<T>(List<T> items, int k) {
    final result = <List<T>>[];
    _combinationsHelper(items, k, 0, <T>[], result);
    return result;
  }

  static void _combinationsHelper<T>(
    List<T> items,
    int k,
    int start,
    List<T> current,
    List<List<T>> result,
  ) {
    if (current.length == k) {
      result.add(List<T>.of(current));
      return;
    }
    for (int i = start; i < items.length; i++) {
      current.add(items[i]);
      _combinationsHelper(items, k, i + 1, current, result);
      current.removeLast();
    }
  }
}

// ---------------------------------------------------------------------------
// Showdown result data classes
// ---------------------------------------------------------------------------

/// Information about a side pot for showdown (mirrors SidePot but avoids
/// import cycle).
class SidePotInfo {
  final double amount;
  final List<int> eligiblePlayerIndices;

  const SidePotInfo({
    required this.amount,
    required this.eligiblePlayerIndices,
  });
}

/// Result of a full showdown evaluation.
class ShowdownResult {
  /// Per-player hand evaluations (only non-folded players with hole cards).
  final Map<int, EvaluatedHand> evaluations;

  /// Per-player chip awards (how much each player wins from all pots).
  final Map<int, double> awards;

  const ShowdownResult({
    required this.evaluations,
    required this.awards,
  });

  /// The indices of players who won at least one pot.
  List<int> get winnerIndices =>
      awards.entries.where((e) => e.value > 0).map((e) => e.key).toList();
}
