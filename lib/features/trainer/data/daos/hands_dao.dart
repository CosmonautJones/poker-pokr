import 'package:drift/drift.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/features/trainer/data/tables/hands_table.dart';
import 'package:poker_trainer/features/trainer/data/tables/actions_table.dart';

part 'hands_dao.g.dart';

@DriftAccessor(tables: [Hands, HandActions])
class HandsDao extends DatabaseAccessor<AppDatabase> with _$HandsDaoMixin {
  HandsDao(super.db);

  Stream<List<Hand>> watchAllHands() => (select(hands)
        ..where((t) => t.parentHandId.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  Future<Hand> getHand(int id) =>
      (select(hands)..where((t) => t.id.equals(id))).getSingle();

  Future<List<HandAction>> getActionsForHand(int handId) => (select(handActions)
        ..where((t) => t.handId.equals(handId))
        ..orderBy([(t) => OrderingTerm.asc(t.sequenceIndex)]))
      .get();

  Future<void> insertHandWithActions(
      HandsCompanion hand, List<HandActionsCompanion> actions) async {
    await transaction(() async {
      final handId = await into(hands).insert(hand);
      for (final action in actions) {
        await into(handActions)
            .insert(action.copyWith(handId: Value(handId)));
      }
    });
  }

  Future<int> deleteHand(int id) async {
    await (delete(handActions)..where((t) => t.handId.equals(id))).go();
    return (delete(hands)..where((t) => t.id.equals(id))).go();
  }
}
