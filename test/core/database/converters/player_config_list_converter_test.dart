import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/database/converters/player_config_list_converter.dart';

void main() {
  const converter = PlayerConfigListConverter();

  group('PlayerConfigListConverter.fromSql', () {
    test('decodes a valid array of player configs', () {
      const json =
          '[{"name":"Alice","stack":200.0,"seatIndex":0},'
          '{"name":"Bob","stack":150.5,"seatIndex":1}]';
      final result = converter.fromSql(json);
      expect(result.length, 2);
      expect(result[0].name, 'Alice');
      expect(result[0].stack, 200.0);
      expect(result[0].seatIndex, 0);
      expect(result[1].name, 'Bob');
      expect(result[1].stack, 150.5);
      expect(result[1].seatIndex, 1);
    });

    test('decodes an empty array', () {
      expect(converter.fromSql('[]'), isEmpty);
    });

    test('throws FormatException for non-list JSON', () {
      expect(
        () => converter.fromSql('{"name":"Alice","stack":200.0,"seatIndex":0}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for array containing non-object element', () {
      expect(
        () => converter.fromSql('[42]'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for malformed JSON', () {
      expect(
        () => converter.fromSql('not-valid-json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('throws FormatException for array containing a string element', () {
      expect(
        () => converter.fromSql('["Alice"]'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('PlayerConfigListConverter.toSql', () {
    test('encodes a list of player configs', () {
      final configs = [
        PlayerConfig(name: 'Alice', stack: 200.0, seatIndex: 0),
        PlayerConfig(name: 'Bob', stack: 150.0, seatIndex: 1),
      ];
      final result = converter.toSql(configs);
      // Round-trip: decode and verify fields are preserved.
      final decoded = converter.fromSql(result);
      expect(decoded.length, 2);
      expect(decoded[0].name, 'Alice');
      expect(decoded[0].stack, 200.0);
      expect(decoded[0].seatIndex, 0);
      expect(decoded[1].name, 'Bob');
      expect(decoded[1].stack, 150.0);
      expect(decoded[1].seatIndex, 1);
    });

    test('encodes an empty list', () {
      expect(converter.toSql([]), '[]');
    });
  });
}
