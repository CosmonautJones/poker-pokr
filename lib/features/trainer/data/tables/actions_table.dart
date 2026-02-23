import 'package:drift/drift.dart';

class HandActions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get handId => integer()();
  IntColumn get sequenceIndex => integer()();
  IntColumn get street => integer()();
  IntColumn get playerPosition => integer()();
  IntColumn get actionType => integer()();
  RealColumn get amount => real().withDefault(const Constant(0.0))();
  RealColumn get potAfterAction => real().withDefault(const Constant(0.0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {handId, sequenceIndex}
      ];
}
