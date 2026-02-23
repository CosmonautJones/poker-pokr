import 'package:drift/drift.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/features/bookkeeper/data/tables/sessions_table.dart';

part 'sessions_dao.g.dart';

@DriftAccessor(tables: [Sessions])
class SessionsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionsDaoMixin {
  SessionsDao(super.db);

  Stream<List<Session>> watchAllSessions() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.date)])).watch();

  Future<int> insertSession(SessionsCompanion entry) =>
      into(sessions).insert(entry);

  Future<bool> updateSession(SessionsCompanion entry) =>
      update(sessions).replace(entry);

  Future<int> deleteSessionById(int id) =>
      (delete(sessions)..where((t) => t.id.equals(id))).go();

  Stream<List<Session>> watchSessionsByDateRange(
          DateTime start, DateTime end) =>
      (select(sessions)
            ..where((t) => t.date.isBetweenValues(start, end))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<List<Session>> getAllSessions() =>
      (select(sessions)..orderBy([(t) => OrderingTerm.desc(t.date)])).get();
}
