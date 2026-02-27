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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(hands, hands.gameType);
            await m.addColumn(hands, hands.straddle);
          }
          if (from < 3) {
            await m.addColumn(hands, hands.dealerIndex);
            await m.addColumn(hands, hands.holeCardsJson);
          }
        },
      );
}
