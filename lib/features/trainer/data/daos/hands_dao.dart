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

  Future<Hand> getHand(int id) async {
    final result = await (select(hands)..where((t) => t.id.equals(id))).getSingleOrNull();
    if (result == null) {
      throw StateError('Hand with id=$id not found in database');
    }
    return result;
  }

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

  /// Insert a hand and its actions, returning the new hand ID.
  Future<int> insertBranchWithActions(
      HandsCompanion hand, List<HandActionsCompanion> actions) async {
    return transaction(() async {
      final handId = await into(hands).insert(hand);
      for (final action in actions) {
        await into(handActions)
            .insert(action.copyWith(handId: Value(handId)));
      }
      return handId;
    });
  }

  /// Insert the primary hand and all branch hands atomically.
  ///
  /// [primaryHand] and [primaryActions] are inserted first.
  /// Each entry in [branches] is a (HandsCompanion, List<HandActionsCompanion>) pair.
  /// Returns the new primary hand ID.
  Future<int> insertHandWithAllBranches(
    HandsCompanion primaryHand,
    List<HandActionsCompanion> primaryActions,
    List<(HandsCompanion, List<HandActionsCompanion>)> branches,
  ) {
    return transaction(() async {
      final parentId = await into(hands).insert(primaryHand);
      for (final action in primaryActions) {
        await into(handActions).insert(action.copyWith(handId: Value(parentId)));
      }
      for (final (branchHand, branchActions) in branches) {
        final branchId = await into(hands).insert(
          branchHand.copyWith(parentHandId: Value(parentId)),
        );
        for (final action in branchActions) {
          await into(handActions).insert(action.copyWith(handId: Value(branchId)));
        }
      }
      return parentId;
    });
  }

  /// Get all branches (child hands) for a given parent hand.
  Future<List<Hand>> getBranchesForHand(int parentId) =>
      (select(hands)
            ..where((t) => t.parentHandId.equals(parentId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  /// Watch only setup-only (saved for practice) hands.
  Stream<List<Hand>> watchSavedSetups() => (select(hands)
        ..where(
            (t) => t.isSetupOnly.equals(true) & t.parentHandId.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// Watch only played (non-setup-only) hands.
  Stream<List<Hand>> watchPlayedHands() => (select(hands)
        ..where(
            (t) => t.isSetupOnly.equals(false) & t.parentHandId.isNull())
        ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
      .watch();

  /// Insert a setup-only hand (no actions, just the configuration).
  Future<int> insertSavedSetup(HandsCompanion hand) {
    return into(hands).insert(
      hand.copyWith(isSetupOnly: const Value(true)),
    );
  }

  /// Delete a hand and cascade-delete its branches and all associated actions.
  ///
  /// Collects all descendant IDs first, then deletes in bulk inside a single
  /// transaction so partial failures cannot leave orphaned records.
  Future<int> deleteHand(int id) {
    return transaction(() async {
      final allIds = await _collectHandIds(id);
      await (delete(handActions)..where((t) => t.handId.isIn(allIds))).go();
      return (delete(hands)..where((t) => t.id.isIn(allIds))).go();
    });
  }

  Future<List<int>> _collectHandIds(int rootId) async {
    final ids = <int>[rootId];
    final queue = <int>[rootId];
    var front = 0;
    while (front < queue.length) {
      final current = queue[front++];
      final branches = await getBranchesForHand(current);
      for (final branch in branches) {
        ids.add(branch.id);
        queue.add(branch.id);
      }
    }
    return ids;
  }
}
