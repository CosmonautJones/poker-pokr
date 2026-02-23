import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/models/card.dart';

void main() {
  group('PokerCard', () {
    group('value -> rank/suit mapping', () {
      test('value 0 is two of clubs', () {
        final card = PokerCard(0);
        expect(card.rank, Rank.two);
        expect(card.suit, Suit.clubs);
      });

      test('value 12 is ace of clubs', () {
        final card = PokerCard(12);
        expect(card.rank, Rank.ace);
        expect(card.suit, Suit.clubs);
      });

      test('value 13 is two of diamonds', () {
        final card = PokerCard(13);
        expect(card.rank, Rank.two);
        expect(card.suit, Suit.diamonds);
      });

      test('value 26 is two of hearts', () {
        final card = PokerCard(26);
        expect(card.rank, Rank.two);
        expect(card.suit, Suit.hearts);
      });

      test('value 39 is two of spades', () {
        final card = PokerCard(39);
        expect(card.rank, Rank.two);
        expect(card.suit, Suit.spades);
      });

      test('value 51 is ace of spades', () {
        final card = PokerCard(51);
        expect(card.rank, Rank.ace);
        expect(card.suit, Suit.spades);
      });

      test('value 30 is seven of hearts', () {
        // hearts start at 26, seven is index 5 => 26 + 5 = 31
        // Actually: Rank.seven has index 5 in Rank enum
        // suit hearts has index 2 => 2 * 13 + 5 = 31
        final card = PokerCard(31);
        expect(card.rank, Rank.seven);
        expect(card.suit, Suit.hearts);
      });
    });

    group('PokerCard.from constructor', () {
      test('constructs from rank and suit', () {
        final card = PokerCard.from(Rank.ace, Suit.spades);
        expect(card.value, 51);
      });

      test('constructs two of clubs as value 0', () {
        final card = PokerCard.from(Rank.two, Suit.clubs);
        expect(card.value, 0);
      });

      test('round-trips through value correctly', () {
        for (int i = 0; i < 52; i++) {
          final card = PokerCard(i);
          final reconstructed = PokerCard.from(card.rank, card.suit);
          expect(reconstructed.value, i);
        }
      });
    });

    group('toString', () {
      test('two of clubs is "2\u2663"', () {
        final card = PokerCard(0);
        expect(card.toString(), '2\u2663');
      });

      test('ace of spades is "A\u2660"', () {
        final card = PokerCard(51);
        expect(card.toString(), 'A\u2660');
      });

      test('ten of hearts is "T\u2665"', () {
        final card = PokerCard.from(Rank.ten, Suit.hearts);
        expect(card.toString(), 'T\u2665');
      });

      test('king of diamonds is "K\u2666"', () {
        final card = PokerCard.from(Rank.king, Suit.diamonds);
        expect(card.toString(), 'K\u2666');
      });

      test('jack of clubs is "J\u2663"', () {
        final card = PokerCard.from(Rank.jack, Suit.clubs);
        expect(card.toString(), 'J\u2663');
      });

      test('queen of spades is "Q\u2660"', () {
        final card = PokerCard.from(Rank.queen, Suit.spades);
        expect(card.toString(), 'Q\u2660');
      });
    });

    group('equality', () {
      test('cards with same value are equal', () {
        expect(PokerCard(0), PokerCard(0));
      });

      test('cards with different values are not equal', () {
        expect(PokerCard(0) == PokerCard(1), false);
      });

      test('PokerCard.from equals PokerCard with same value', () {
        expect(PokerCard.from(Rank.ace, Suit.spades), PokerCard(51));
      });
    });
  });

  group('Rank', () {
    test('numeric values are 2 through 14', () {
      expect(Rank.two.value, 2);
      expect(Rank.three.value, 3);
      expect(Rank.ten.value, 10);
      expect(Rank.jack.value, 11);
      expect(Rank.queen.value, 12);
      expect(Rank.king.value, 13);
      expect(Rank.ace.value, 14);
    });
  });

  group('Deck', () {
    test('deals 52 unique cards', () {
      final deck = Deck(seed: 42);
      final dealt = <PokerCard>[];
      while (deck.remaining > 0) {
        dealt.add(deck.deal());
      }
      expect(dealt.length, 52);

      // All unique values
      final values = dealt.map((c) => c.value).toSet();
      expect(values.length, 52);

      // Contains all values 0-51
      for (int i = 0; i < 52; i++) {
        expect(values.contains(i), true, reason: 'Missing card value $i');
      }
    });

    test('with seed is deterministic', () {
      final deck1 = Deck(seed: 123);
      final deck2 = Deck(seed: 123);
      final cards1 = <int>[];
      final cards2 = <int>[];

      for (int i = 0; i < 52; i++) {
        cards1.add(deck1.deal().value);
        cards2.add(deck2.deal().value);
      }

      expect(cards1, cards2);
    });

    test('different seeds produce different orders', () {
      final deck1 = Deck(seed: 1);
      final deck2 = Deck(seed: 2);
      final cards1 = <int>[];
      final cards2 = <int>[];

      for (int i = 0; i < 52; i++) {
        cards1.add(deck1.deal().value);
        cards2.add(deck2.deal().value);
      }

      // Extremely unlikely to be the same
      expect(cards1, isNot(cards2));
    });

    test('throws StateError when dealing from empty deck', () {
      final deck = Deck(seed: 1);
      // Deal all 52 cards
      for (int i = 0; i < 52; i++) {
        deck.deal();
      }
      expect(() => deck.deal(), throwsStateError);
    });

    test('remaining count decreases as cards are dealt', () {
      final deck = Deck(seed: 1);
      expect(deck.remaining, 52);

      deck.deal();
      expect(deck.remaining, 51);

      deck.dealMany(5);
      expect(deck.remaining, 46);
    });

    test('dealMany returns correct number of cards', () {
      final deck = Deck(seed: 1);
      final cards = deck.dealMany(5);
      expect(cards.length, 5);
    });

    test('remove removes specific cards from deck', () {
      final deck = Deck(seed: 1);
      final toRemove = [PokerCard(0), PokerCard(51)];
      deck.remove(toRemove);

      expect(deck.remaining, 50);
      // Deal all remaining and check that removed cards are not present
      final remaining = <int>[];
      while (deck.remaining > 0) {
        remaining.add(deck.deal().value);
      }
      expect(remaining.contains(0), false);
      expect(remaining.contains(51), false);
    });
  });
}
