import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/poker_glossary.dart';

void main() {
  group('PokerGlossary', () {
    test('entries is not empty', () {
      expect(PokerGlossary.entries, isNotEmpty);
    });

    test('all entries have non-empty fields', () {
      for (final entry in PokerGlossary.entries) {
        expect(entry.term, isNotEmpty, reason: 'term for ${entry.abbreviation}');
        expect(entry.abbreviation, isNotEmpty,
            reason: 'abbreviation for ${entry.term}');
        expect(entry.definition, isNotEmpty,
            reason: 'definition for ${entry.term}');
        expect(entry.category, isNotEmpty,
            reason: 'category for ${entry.term}');
      }
    });

    group('categories', () {
      test('returns 5 categories', () {
        expect(PokerGlossary.categories.length, 5);
      });

      test('contains all expected categories', () {
        expect(PokerGlossary.categories, containsAll([
          PokerGlossary.categoryPositions,
          PokerGlossary.categoryBetting,
          PokerGlossary.categoryConcepts,
          PokerGlossary.categoryHands,
          PokerGlossary.categoryStreets,
        ]));
      });

      test('every entry belongs to a known category', () {
        final validCategories = PokerGlossary.categories.toSet();
        for (final entry in PokerGlossary.entries) {
          expect(validCategories, contains(entry.category),
              reason: '${entry.term} has unknown category "${entry.category}"');
        }
      });
    });

    group('lookup', () {
      test('finds BTN by exact abbreviation', () {
        final entry = PokerGlossary.lookup('BTN');
        expect(entry, isNotNull);
        expect(entry!.term, 'Button');
      });

      test('lookup is case-insensitive', () {
        final entry = PokerGlossary.lookup('btn');
        expect(entry, isNotNull);
        expect(entry!.abbreviation, 'BTN');
      });

      test('returns null for unknown term', () {
        expect(PokerGlossary.lookup('ZZZZ'), isNull);
      });

      test('finds SPR', () {
        final entry = PokerGlossary.lookup('SPR');
        expect(entry, isNotNull);
        expect(entry!.term, 'Stack-to-Pot Ratio');
      });

      test('finds Pot Odds', () {
        final entry = PokerGlossary.lookup('Pot Odds');
        expect(entry, isNotNull);
        expect(entry!.category, PokerGlossary.categoryBetting);
      });
    });

    group('byCategory', () {
      test('returns only entries matching the category', () {
        final positions = PokerGlossary.byCategory(PokerGlossary.categoryPositions);
        expect(positions, isNotEmpty);
        for (final entry in positions) {
          expect(entry.category, PokerGlossary.categoryPositions);
        }
      });

      test('returns empty list for unknown category', () {
        expect(PokerGlossary.byCategory('Nonexistent'), isEmpty);
      });

      test('all categories have at least one entry', () {
        for (final category in PokerGlossary.categories) {
          expect(
            PokerGlossary.byCategory(category),
            isNotEmpty,
            reason: 'Category "$category" has no entries',
          );
        }
      });

      test('positions category includes BTN, SB, BB', () {
        final positions = PokerGlossary.byCategory(PokerGlossary.categoryPositions);
        final abbreviations = positions.map((e) => e.abbreviation).toSet();
        expect(abbreviations, containsAll(['BTN', 'SB', 'BB']));
      });

      test('streets category includes Preflop through Showdown', () {
        final streets = PokerGlossary.byCategory(PokerGlossary.categoryStreets);
        final terms = streets.map((e) => e.term).toSet();
        expect(terms, containsAll(['Preflop', 'Flop', 'Turn', 'River', 'Showdown']));
      });
    });

    test('no duplicate abbreviations', () {
      final abbreviations = PokerGlossary.entries.map((e) => e.abbreviation.toLowerCase()).toList();
      final unique = abbreviations.toSet();
      expect(unique.length, abbreviations.length,
          reason: 'Duplicate abbreviations found');
    });
  });
}
