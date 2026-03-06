import 'dart:convert';
import 'package:drift/drift.dart';

class CardListConverter extends TypeConverter<List<int>, String> {
  const CardListConverter();

  @override
  List<int> fromSql(String fromDb) {
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is! List) {
        throw FormatException('Expected JSON array for card list, got ${decoded.runtimeType}');
      }
      return decoded.map((e) {
        if (e is! int) throw FormatException('Non-int card value: $e (${e.runtimeType})');
        return e;
      }).toList();
    } catch (e) {
      throw FormatException('Invalid card list JSON "$fromDb": $e');
    }
  }

  @override
  String toSql(List<int> value) => jsonEncode(value);
}
