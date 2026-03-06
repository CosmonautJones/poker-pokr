import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/database/converters/card_list_converter.dart';

void main() {
  const converter = CardListConverter();

  group('CardListConverter.fromSql', () {
    test('decodes a valid list of ints', () {
      expect(converter.fromSql('[0,1,2,51]'), [0, 1, 2, 51]);
    });

    test('decodes an empty list', () {
      expect(converter.fromSql('[]'), isEmpty);
    });

    test('throws FormatException for non-list JSON', () {
      expect(() => converter.fromSql('{"key":1}'), throwsA(isA<FormatException>()));
    });

    test('throws FormatException for list containing non-int', () {
      expect(() => converter.fromSql('[0,"ace",2]'), throwsA(isA<FormatException>()));
    });

    test('throws FormatException for malformed JSON', () {
      expect(() => converter.fromSql('not-json'), throwsA(isA<FormatException>()));
    });
  });

  group('CardListConverter.toSql', () {
    test('encodes a list of ints', () {
      expect(converter.toSql([0, 1, 51]), '[0,1,51]');
    });

    test('encodes an empty list', () {
      expect(converter.toSql([]), '[]');
    });
  });
}
