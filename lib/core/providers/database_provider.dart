import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/features/bookkeeper/data/daos/sessions_dao.dart';
import 'package:poker_trainer/features/trainer/data/daos/hands_dao.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final sessionsDaoProvider = Provider<SessionsDao>((ref) =>
    ref.watch(databaseProvider).sessionsDao);

final handsDaoProvider = Provider<HandsDao>((ref) =>
    ref.watch(databaseProvider).handsDao);
