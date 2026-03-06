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
  List<PlayerConfig> fromSql(String fromDb) {
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is! List) {
        throw FormatException('Expected JSON array for player configs, got ${decoded.runtimeType}');
      }
      return decoded.map((e) {
        if (e is! Map) throw FormatException('Expected JSON object for player config, got ${e.runtimeType}');
        return PlayerConfig.fromJson(e as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw FormatException('Invalid player config JSON "$fromDb": $e');
    }
  }

  @override
  String toSql(List<PlayerConfig> value) =>
      jsonEncode(value.map((e) => e.toJson()).toList());
}
