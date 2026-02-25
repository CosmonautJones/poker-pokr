import 'package:drift/drift.dart';
import 'package:poker_trainer/core/database/converters/card_list_converter.dart';
import 'package:poker_trainer/core/database/converters/player_config_list_converter.dart';

class Hands extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().nullable()();
  TextColumn get description => text().nullable()();
  IntColumn get playerCount => integer()();
  RealColumn get smallBlind => real()();
  RealColumn get bigBlind => real()();
  RealColumn get ante => real().withDefault(const Constant(0.0))();
  TextColumn get playerConfigs =>
      text().map(const PlayerConfigListConverter())();
  TextColumn get communityCards => text().map(const CardListConverter())();
  IntColumn get gameType => integer().withDefault(const Constant(0))();
  RealColumn get straddle => real().withDefault(const Constant(0.0))();
  IntColumn get parentHandId => integer().nullable()();
  IntColumn get branchAtActionIndex => integer().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
