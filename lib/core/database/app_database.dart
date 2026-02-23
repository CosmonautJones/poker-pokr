import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:poker_trainer/core/database/converters/card_list_converter.dart';
import 'package:poker_trainer/core/database/converters/player_config_list_converter.dart';
import 'package:poker_trainer/features/bookkeeper/data/tables/sessions_table.dart';
import 'package:poker_trainer/features/bookkeeper/data/tables/tags_table.dart';
import 'package:poker_trainer/features/trainer/data/tables/hands_table.dart';
import 'package:poker_trainer/features/trainer/data/tables/actions_table.dart';
import 'package:poker_trainer/features/bookkeeper/data/daos/sessions_dao.dart';
import 'package:poker_trainer/features/trainer/data/daos/hands_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Sessions, Tags, SessionTags, Hands, HandActions],
  daos: [SessionsDao, HandsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(driftDatabase(
          name: 'poker_trainer',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
      );
}
