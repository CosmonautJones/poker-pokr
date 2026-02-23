import 'dart:convert';
import 'package:drift/drift.dart';

class CardListConverter extends TypeConverter<List<int>, String> {
  const CardListConverter();

  @override
  List<int> fromSql(String fromDb) =>
      (jsonDecode(fromDb) as List).cast<int>();

  @override
  String toSql(List<int> value) => jsonEncode(value);
}
