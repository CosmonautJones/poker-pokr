import 'dart:convert';
import 'package:drift/drift.dart';

class PlayerConfig {
  final String name;
  final double stack;
  final int seatIndex;

  const PlayerConfig({
    required this.name,
    required this.stack,
    required this.seatIndex,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'stack': stack,
        'seatIndex': seatIndex,
      };

  factory PlayerConfig.fromJson(Map<String, dynamic> json) => PlayerConfig(
        name: json['name'] as String,
        stack: (json['stack'] as num).toDouble(),
        seatIndex: json['seatIndex'] as int,
      );
}

class PlayerConfigListConverter
    extends TypeConverter<List<PlayerConfig>, String> {
  const PlayerConfigListConverter();

  @override
  List<PlayerConfig> fromSql(String fromDb) => (jsonDecode(fromDb) as List)
      .map((e) => PlayerConfig.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  String toSql(List<PlayerConfig> value) =>
      jsonEncode(value.map((e) => e.toJson()).toList());
}
