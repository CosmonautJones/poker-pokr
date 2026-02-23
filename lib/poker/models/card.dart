/// Playing card representations for a standard 52-card deck.
///
/// Pure Dart - no Flutter imports.
library;

enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace;

  /// Numeric value: 2 for two, ..., 14 for ace.
  int get value => index + 2;

  String get symbol => switch (this) {
        Rank.two => '2',
        Rank.three => '3',
        Rank.four => '4',
        Rank.five => '5',
        Rank.six => '6',
        Rank.seven => '7',
        Rank.eight => '8',
        Rank.nine => '9',
        Rank.ten => 'T',
        Rank.jack => 'J',
        Rank.queen => 'Q',
        Rank.king => 'K',
        Rank.ace => 'A',
      };
}

enum Suit {
  clubs,
  diamonds,
  hearts,
  spades;

  String get symbol => switch (this) {
        Suit.clubs => '\u2663',
        Suit.diamonds => '\u2666',
        Suit.hearts => '\u2665',
        Suit.spades => '\u2660',
      };
}

/// An immutable playing card represented as a single integer 0-51.
///
/// Encoding: `value = suit.index * 13 + rank.index`
///   - cards 0-12  are clubs    (2c .. Ac)
///   - cards 13-25 are diamonds (2d .. Ad)
///   - cards 26-38 are hearts   (2h .. Ah)
///   - cards 39-51 are spades   (2s .. As)
class PokerCard {
  final int value;

  const PokerCard(this.value)
      : assert(value >= 0 && value <= 51, 'Card value must be 0-51');

  /// Construct from explicit rank and suit.
  PokerCard.from(Rank rank, Suit suit)
      : value = suit.index * 13 + rank.index;

  Rank get rank => Rank.values[value % 13];
  Suit get suit => Suit.values[value ~/ 13];

  @override
  String toString() => '${rank.symbol}${suit.symbol}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is PokerCard && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// A standard 52-card deck that can be shuffled and dealt from.
class Deck {
  final List<PokerCard> _cards;

  /// Creates a full 52-card deck in a shuffled order.
  ///
  /// An optional [seed] can be supplied for deterministic shuffling (useful in
  /// tests).
  Deck({int? seed}) : _cards = _buildShuffled(seed);

  /// Creates a deck from a pre-ordered list of cards (top of deck = last
  /// element, so that [deal] pops from the end efficiently).
  Deck.fromCards(List<PokerCard> cards) : _cards = List<PokerCard>.of(cards);

  static List<PokerCard> _buildShuffled(int? seed) {
    final cards = [for (int i = 0; i < 52; i++) PokerCard(i)];
    if (seed != null) {
      // Use a simple seeded Fisher-Yates shuffle for determinism.
      final rng = _SeededRandom(seed);
      for (int i = cards.length - 1; i > 0; i--) {
        final j = rng.nextInt(i + 1);
        final tmp = cards[i];
        cards[i] = cards[j];
        cards[j] = tmp;
      }
    } else {
      cards.shuffle();
    }
    return cards;
  }

  /// Number of cards remaining in the deck.
  int get remaining => _cards.length;

  /// Deal (remove and return) the top card of the deck.
  PokerCard deal() {
    if (_cards.isEmpty) {
      throw StateError('Cannot deal from an empty deck');
    }
    return _cards.removeLast();
  }

  /// Deal [count] cards from the top of the deck.
  List<PokerCard> dealMany(int count) =>
      [for (int i = 0; i < count; i++) deal()];

  /// Remove specific cards from the deck (used when hole cards are
  /// pre-assigned).
  void remove(Iterable<PokerCard> cards) {
    final toRemove = cards.map((c) => c.value).toSet();
    _cards.removeWhere((c) => toRemove.contains(c.value));
  }

  /// Returns an unmodifiable view of the remaining cards (top = last element).
  List<PokerCard> get cards => List.unmodifiable(_cards);
}

/// Minimal seeded PRNG (xorshift32) so tests can be deterministic.
class _SeededRandom {
  int _state;

  _SeededRandom(int seed) : _state = seed == 0 ? 1 : seed;

  int nextInt(int max) {
    // xorshift32
    _state ^= _state << 13;
    _state ^= _state >> 17;
    _state ^= _state << 5;
    return (_state.abs()) % max;
  }
}
