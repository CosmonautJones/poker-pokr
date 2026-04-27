/// Standard poker hand rankings, strongest to weakest.
///
/// Pure Dart - no Flutter imports. Used by the Learn Hub's hand-ranking
/// reference and any UI that needs canonical ranking metadata.
library;

import 'package:poker_trainer/poker/models/card.dart';

/// A canonical poker hand category with rank, name, and a representative
/// example. Examples use real PokerCard values so the UI can render them with
/// the existing card widgets.
class HandRanking {
  /// 1 = strongest (royal flush), 10 = weakest (high card).
  final int rank;
  final String name;

  /// One-line summary suitable for a card subtitle.
  final String summary;

  /// Longer description with the rule and a memorable example.
  final String description;

  /// Five cards illustrating the category (best 5).
  final List<PokerCard> example;

  /// Combined-frequency probability of being dealt this category in a 5-card
  /// hand from a standard 52-card deck. Stored as a percent (0-100).
  ///
  /// Source: standard combinatorial poker probability tables.
  final double probabilityPercent;

  const HandRanking({
    required this.rank,
    required this.name,
    required this.summary,
    required this.description,
    required this.example,
    required this.probabilityPercent,
  });
}

/// All ten hand categories in display order (strongest first).
class HandRankings {
  HandRankings._();

  static final List<HandRanking> all = [
    HandRanking(
      rank: 1,
      name: 'Royal Flush',
      summary: 'A K Q J 10, all one suit',
      description:
          'The strongest possible hand: a ten-high straight flush. Cannot be beaten — only tied with another royal flush of a different suit (extremely rare).',
      example: [
        PokerCard.from(Rank.ten, Suit.spades),
        PokerCard.from(Rank.jack, Suit.spades),
        PokerCard.from(Rank.queen, Suit.spades),
        PokerCard.from(Rank.king, Suit.spades),
        PokerCard.from(Rank.ace, Suit.spades),
      ],
      probabilityPercent: 0.000154,
    ),
    HandRanking(
      rank: 2,
      name: 'Straight Flush',
      summary: 'Five consecutive cards of one suit',
      description:
          'Any five cards in sequence and of the same suit. Ace can play low (A-2-3-4-5, the "wheel") or high (T-J-Q-K-A, royal). Beats four of a kind.',
      example: [
        PokerCard.from(Rank.five, Suit.hearts),
        PokerCard.from(Rank.six, Suit.hearts),
        PokerCard.from(Rank.seven, Suit.hearts),
        PokerCard.from(Rank.eight, Suit.hearts),
        PokerCard.from(Rank.nine, Suit.hearts),
      ],
      probabilityPercent: 0.00139,
    ),
    HandRanking(
      rank: 3,
      name: 'Four of a Kind',
      summary: 'Four cards of the same rank',
      description:
          'Also called "quads". Tie-broken first by the four-of-a-kind rank, then by the kicker. Quad aces is the strongest non-flush hand.',
      example: [
        PokerCard.from(Rank.king, Suit.clubs),
        PokerCard.from(Rank.king, Suit.diamonds),
        PokerCard.from(Rank.king, Suit.hearts),
        PokerCard.from(Rank.king, Suit.spades),
        PokerCard.from(Rank.three, Suit.clubs),
      ],
      probabilityPercent: 0.0240,
    ),
    HandRanking(
      rank: 4,
      name: 'Full House',
      summary: 'Three of a kind plus a pair',
      description:
          'Read aloud as "trips full of pair", e.g. "aces full of jacks". Tie-broken by the trips first, then the pair.',
      example: [
        PokerCard.from(Rank.ace, Suit.hearts),
        PokerCard.from(Rank.ace, Suit.diamonds),
        PokerCard.from(Rank.ace, Suit.clubs),
        PokerCard.from(Rank.jack, Suit.spades),
        PokerCard.from(Rank.jack, Suit.hearts),
      ],
      probabilityPercent: 0.1441,
    ),
    HandRanking(
      rank: 5,
      name: 'Flush',
      summary: 'Five cards of one suit, not in sequence',
      description:
          'Tie-broken by the highest card, then second-highest, and so on. The suit itself never breaks ties in standard poker.',
      example: [
        PokerCard.from(Rank.two, Suit.diamonds),
        PokerCard.from(Rank.six, Suit.diamonds),
        PokerCard.from(Rank.nine, Suit.diamonds),
        PokerCard.from(Rank.jack, Suit.diamonds),
        PokerCard.from(Rank.king, Suit.diamonds),
      ],
      probabilityPercent: 0.1965,
    ),
    HandRanking(
      rank: 6,
      name: 'Straight',
      summary: 'Five consecutive cards, mixed suits',
      description:
          'Ace can play low (A-2-3-4-5, "wheel") or high (T-J-Q-K-A, "Broadway"). Wraparound straights like Q-K-A-2-3 are not valid.',
      example: [
        PokerCard.from(Rank.four, Suit.clubs),
        PokerCard.from(Rank.five, Suit.diamonds),
        PokerCard.from(Rank.six, Suit.spades),
        PokerCard.from(Rank.seven, Suit.hearts),
        PokerCard.from(Rank.eight, Suit.clubs),
      ],
      probabilityPercent: 0.3925,
    ),
    HandRanking(
      rank: 7,
      name: 'Three of a Kind',
      summary: 'Three cards of the same rank',
      description:
          'A "set" is when the trips include a pocket pair; "trips" is when they include only one hole card. Sets play more concealed and win bigger pots.',
      example: [
        PokerCard.from(Rank.queen, Suit.hearts),
        PokerCard.from(Rank.queen, Suit.spades),
        PokerCard.from(Rank.queen, Suit.diamonds),
        PokerCard.from(Rank.eight, Suit.clubs),
        PokerCard.from(Rank.three, Suit.diamonds),
      ],
      probabilityPercent: 2.1128,
    ),
    HandRanking(
      rank: 8,
      name: 'Two Pair',
      summary: 'Two different pairs',
      description:
          'Read as "higher pair and lower pair", e.g. "aces and eights" — the dead-man\'s hand. Tie-broken by the higher pair, then lower, then the kicker.',
      example: [
        PokerCard.from(Rank.ace, Suit.spades),
        PokerCard.from(Rank.ace, Suit.clubs),
        PokerCard.from(Rank.eight, Suit.spades),
        PokerCard.from(Rank.eight, Suit.clubs),
        PokerCard.from(Rank.king, Suit.diamonds),
      ],
      probabilityPercent: 4.7539,
    ),
    HandRanking(
      rank: 9,
      name: 'One Pair',
      summary: 'Two cards of the same rank',
      description:
          'Tie-broken by the pair rank, then by up to three kickers in order. Top pair with a strong kicker is a common winning hand.',
      example: [
        PokerCard.from(Rank.ten, Suit.hearts),
        PokerCard.from(Rank.ten, Suit.spades),
        PokerCard.from(Rank.king, Suit.diamonds),
        PokerCard.from(Rank.seven, Suit.clubs),
        PokerCard.from(Rank.three, Suit.spades),
      ],
      probabilityPercent: 42.2569,
    ),
    HandRanking(
      rank: 10,
      name: 'High Card',
      summary: 'No pair — highest card plays',
      description:
          'When no other category is made. Tie-broken by comparing the five cards in descending order. Often loses unless opponents missed entirely.',
      example: [
        PokerCard.from(Rank.ace, Suit.diamonds),
        PokerCard.from(Rank.jack, Suit.spades),
        PokerCard.from(Rank.eight, Suit.hearts),
        PokerCard.from(Rank.five, Suit.clubs),
        PokerCard.from(Rank.three, Suit.diamonds),
      ],
      probabilityPercent: 50.1177,
    ),
  ];

  /// Lookup by rank (1 = royal flush, 10 = high card).
  static HandRanking byRank(int rank) =>
      all.firstWhere((h) => h.rank == rank);
}
