import 'package:drift/drift.dart';
import 'package:poker_trainer/features/bookkeeper/data/tables/sessions_table.dart';

class Tags extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 50)();
  IntColumn get color => integer().withDefault(const Constant(0xFF4CAF50))();
}

class SessionTags extends Table {
  IntColumn get sessionId => integer().references(Sessions, #id)();
  IntColumn get tagId => integer().references(Tags, #id)();

  @override
  Set<Column> get primaryKey => {sessionId, tagId};
}
