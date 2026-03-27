/// Calculates the number of outs (unseen cards that improve a hand).
///
/// Pure Dart - no Flutter imports.
library;

import '../models/card.dart';
import '../models/game_type.dart';
import 'hand_evaluator.dart';

/// Result of an outs calculation for a single player.
class OutsResult {
  /// Number of unseen cards that improve the player's hand.
  final int outs;

  /// Rough equity estimate using the rule of 2 and 4.
  /// Multiply outs by 4 on the flop, by 2 on the turn.
  final double roughEquityPercent;

  /// Human-readable draw type descriptions (e.g., "flush draw", "gutshot").
  final List<String> drawTypes;

  const OutsResult({
    required this.outs,
    required this.roughEquityPercent,
    required this.drawTypes,
  });

  @override
  String toString() => 'OutsResult(outs: $outs, ~$roughEquityPercent%, '
      'draws: $drawTypes)';
}

class OutsCalculator {
  OutsCalculator._();

  /// Calculate outs for a player's hand given the current board.
  ///
  /// [holeCards] - the player's hole cards.
  /// [communityCards] - current community cards (3 on flop, 4 on turn).
  /// [gameType] - determines evaluation rules (Hold'em vs Omaha).
  /// [deadCards] - other known cards that cannot appear (e.g., other players'
  ///   hole cards visible in trainer mode).
  /// [cardsTocome] - number of cards still to be dealt (2 on flop, 1 on turn).
  ///   Defaults based on community card count.
  static OutsResult calculate({
    required List<PokerCard> holeCards,
    required List<PokerCard> communityCards,
    required GameType gameType,
    List<PokerCard> deadCards = const [],
    int? cardsToCome,
  }) {
    // No outs calculation on preflop (< 3 community) or river (5 community).
    if (communityCards.length < 3 || communityCards.length >= 5) {
      return const OutsResult(
        outs: 0,
        roughEquityPercent: 0,
        drawTypes: [],
      );
    }

    final int remaining = cardsToCome ?? (5 - communityCards.length);

    // Build the set of known cards.
    final known = <int>{};
    for (final c in holeCards) {
      known.add(c.value);
    }
    for (final c in communityCards) {
      known.add(c.value);
    }
    for (final c in deadCards) {
      known.add(c.value);
    }

    // Evaluate current hand.
    final currentHand = HandEvaluator.evaluateBest(
      holeCards,
      communityCards,
      gameType,
    );

    // Test each unseen card: does adding it to the board improve the hand?
    int outCount = 0;
    for (int v = 0; v < 52; v++) {
      if (known.contains(v)) continue;

      final testCard = PokerCard(v);
      final testCommunity = [...communityCards, testCard];
      final testHand = HandEvaluator.evaluateBest(
        holeCards,
        testCommunity,
        gameType,
      );

      if (testHand > currentHand) {
        outCount++;
      }
    }

    // Rule of 2 and 4 estimate.
    final multiplier = remaining >= 2 ? 4 : 2;
    final roughEquity = (outCount * multiplier).clamp(0, 100).toDouble();

    // Detect draw types.
    final drawTypes = _detectDrawTypes(holeCards, communityCards, gameType);

    return OutsResult(
      outs: outCount,
      roughEquityPercent: roughEquity,
      drawTypes: drawTypes,
    );
  }

  /// Detect common draw types from the hand + board.
  static List<String> _detectDrawTypes(
    List<PokerCard> holeCards,
    List<PokerCard> communityCards,
    GameType gameType,
  ) {
    final draws = <String>[];
    final allCards = [...holeCards, ...communityCards];

    // --- Flush draw detection ---
    final suitCounts = <Suit, int>{};
    for (final c in allCards) {
      suitCounts[c.suit] = (suitCounts[c.suit] ?? 0) + 1;
    }
    for (final entry in suitCounts.entries) {
      if (entry.value == 4) {
        draws.add('flush draw');
        break;
      }
    }

    // --- Straight draw detection ---
    final ranks = allCards.map((c) => c.rank.value).toSet().toList()..sort();
    // Add ace-low (1) if ace is present.
    if (ranks.contains(14)) {
      ranks.insert(0, 1);
    }

    // Check for open-ended straight draw (4 consecutive, not already a straight).
    bool hasOESD = false;
    bool hasGutshot = false;

    // Check all possible 5-card straight windows (1-5 through 10-14).
    for (int low = 1; low <= 10; low++) {
      final window = List.generate(5, (i) => low + i);
      final have = window.where((r) => ranks.contains(r)).length;
      final missing = window.where((r) => !ranks.contains(r)).length;

      if (have == 5) {
        // Already have a straight, skip.
        continue;
      }
      if (have == 4 && missing == 1) {
        final missingRank = window.firstWhere((r) => !ranks.contains(r));
        // Open-ended: missing card is at the edge of the window.
        if (missingRank == window.first || missingRank == window.last) {
          hasOESD = true;
        } else {
          hasGutshot = true;
        }
      }
    }

    if (hasOESD) draws.add('open-ended straight draw');
    if (hasGutshot && !hasOESD) draws.add('gutshot straight draw');

    // --- Overcard detection ---
    if (communityCards.isNotEmpty) {
      final boardMax =
          communityCards.map((c) => c.rank.value).reduce((a, b) => a > b ? a : b);
      final overcards =
          holeCards.where((c) => c.rank.value > boardMax).length;
      if (overcards >= 2) {
        draws.add('two overcards');
      } else if (overcards == 1) {
        draws.add('one overcard');
      }
    }

    return draws;
  }
}
