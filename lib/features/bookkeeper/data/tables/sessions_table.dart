import 'package:drift/drift.dart';

class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  IntColumn get gameType =>
      integer().withDefault(const Constant(0))(); // 0=NLH, 1=PLO
  IntColumn get format =>
      integer().withDefault(const Constant(0))(); // 0=cash, 1=tournament
  TextColumn get location => text().withLength(max: 100)();
  TextColumn get stakes => text().withLength(max: 20)();
  RealColumn get buyIn => real()();
  RealColumn get cashOut => real()();
  RealColumn get profitLoss => real()();
  RealColumn get hoursPlayed => real()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
