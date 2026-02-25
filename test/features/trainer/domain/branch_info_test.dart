import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/branch_info.dart';

void main() {
  group('BranchInfo', () {
    test('creates with required fields', () {
      const info = BranchInfo(label: 'Line A');
      expect(info.label, 'Line A');
      expect(info.dbHandId, isNull);
      expect(info.forkAtActionIndex, 0);
    });

    test('creates with all fields', () {
      const info = BranchInfo(
        label: 'Line B',
        dbHandId: 42,
        forkAtActionIndex: 5,
      );
      expect(info.label, 'Line B');
      expect(info.dbHandId, 42);
      expect(info.forkAtActionIndex, 5);
    });

    group('copyWith', () {
      test('copies with changed label', () {
        const info = BranchInfo(label: 'Line A');
        final copy = info.copyWith(label: 'Line Z');
        expect(copy.label, 'Line Z');
        expect(copy.forkAtActionIndex, 0);
      });

      test('copies with changed dbHandId', () {
        const info = BranchInfo(label: 'Line A');
        final copy = info.copyWith(dbHandId: () => 99);
        expect(copy.dbHandId, 99);
      });

      test('can set dbHandId to null', () {
        const info = BranchInfo(label: 'Line A', dbHandId: 42);
        final copy = info.copyWith(dbHandId: () => null);
        expect(copy.dbHandId, isNull);
      });

      test('unchanged fields are preserved', () {
        const info = BranchInfo(
          label: 'Line B',
          dbHandId: 10,
          forkAtActionIndex: 3,
        );
        final copy = info.copyWith(label: 'Line C');
        expect(copy.dbHandId, 10);
        expect(copy.forkAtActionIndex, 3);
      });
    });
  });
}
