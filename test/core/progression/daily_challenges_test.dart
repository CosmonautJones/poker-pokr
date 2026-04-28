import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/daily_challenges.dart';

void main() {
  group('DailyChallenges.forDate', () {
    test('returns dailyCount distinct challenges', () {
      final list = DailyChallenges.forDate(DateTime(2026, 4, 28));
      expect(list, hasLength(DailyChallenges.dailyCount));
      final ids = list.map((c) => c.definitionId).toSet();
      expect(ids.length, list.length, reason: 'ids must be distinct');
    });

    test('is deterministic for the same calendar day', () {
      final a = DailyChallenges.forDate(DateTime(2026, 4, 28, 9));
      final b = DailyChallenges.forDate(DateTime(2026, 4, 28, 23, 59));
      expect(
        a.map((c) => c.definitionId).toList(),
        b.map((c) => c.definitionId).toList(),
      );
    });

    test('rotates between days', () {
      // We expect at least one differing slate across consecutive days for a
      // few sample days — guard against a degenerate seed.
      final samples = <List<String>>[];
      for (int i = 0; i < 5; i++) {
        samples.add(
          DailyChallenges.forDate(DateTime(2026, 4, 28 + i))
              .map((c) => c.definitionId)
              .toList(),
        );
      }
      final unique = samples.map((s) => s.join(',')).toSet();
      expect(unique.length, greaterThan(1));
    });

    test('every emitted id resolves to a definition', () {
      final list = DailyChallenges.forDate(DateTime(2026, 1, 1));
      for (final c in list) {
        expect(DailyChallenges.byId(c.definitionId), isNotNull);
        expect(c.completed, isFalse);
        expect(c.progress, 0);
      }
    });
  });

  group('encode / decode snapshot', () {
    test('round-trip on the same day returns the saved list', () {
      final today = DateTime(2026, 4, 28);
      final list = DailyChallenges.forDate(today);
      final encoded = DailyChallenges.encodeSnapshot(today, list);
      final decoded = DailyChallenges.tryDecodeForToday(encoded, today);
      expect(decoded, isNotNull);
      expect(
        decoded!.map((c) => c.definitionId).toList(),
        list.map((c) => c.definitionId).toList(),
      );
    });

    test('returns null when the stored date is older than today', () {
      final yesterday = DateTime(2026, 4, 27);
      final today = DateTime(2026, 4, 28);
      final encoded = DailyChallenges.encodeSnapshot(
        yesterday,
        DailyChallenges.forDate(yesterday),
      );
      expect(DailyChallenges.tryDecodeForToday(encoded, today), isNull);
    });

    test('returns null on malformed input', () {
      expect(
        DailyChallenges.tryDecodeForToday('not json', DateTime(2026, 4, 28)),
        isNull,
      );
      expect(
        DailyChallenges.tryDecodeForToday(null, DateTime(2026, 4, 28)),
        isNull,
      );
    });
  });

  group('applyIncrement', () {
    test('adds progress without completing when below target', () {
      // Find a challenge with target > 1 to exercise the partial path.
      final play3 = DailyChallenges.byId('play_3')!;
      final list = [
        DailyChallenge(
          definitionId: play3.id,
          progress: 0,
          completed: false,
          date: DateTime(2026, 4, 28),
        ),
      ];
      final result = DailyChallenges.applyIncrement(list, play3.id, 1);
      expect(result.list.first.progress, 1);
      expect(result.list.first.completed, isFalse);
      expect(result.justCompleted, isNull);
    });

    test('flips completed and reports justCompleted on threshold', () {
      final lesson1 = DailyChallenges.byId('lesson_1')!;
      final list = [
        DailyChallenge(
          definitionId: lesson1.id,
          progress: 0,
          completed: false,
          date: DateTime(2026, 4, 28),
        ),
      ];
      final result = DailyChallenges.applyIncrement(list, lesson1.id, 1);
      expect(result.list.first.completed, isTrue);
      expect(result.justCompleted, isNotNull);
      expect(result.justCompleted!.definitionId, lesson1.id);
    });

    test('caps progress at target on overshoot', () {
      final play3 = DailyChallenges.byId('play_3')!;
      final list = [
        DailyChallenge(
          definitionId: play3.id,
          progress: 0,
          completed: false,
          date: DateTime(2026, 4, 28),
        ),
      ];
      final result = DailyChallenges.applyIncrement(list, play3.id, 10);
      expect(result.list.first.progress, play3.target);
      expect(result.list.first.completed, isTrue);
    });

    test('subsequent increments after completion are no-ops', () {
      final lesson1 = DailyChallenges.byId('lesson_1')!;
      final list = [
        DailyChallenge(
          definitionId: lesson1.id,
          progress: lesson1.target,
          completed: true,
          date: DateTime(2026, 4, 28),
        ),
      ];
      final result = DailyChallenges.applyIncrement(list, lesson1.id, 1);
      expect(identical(result.list, list), isTrue);
      expect(result.justCompleted, isNull);
    });

    test('unknown id is a no-op', () {
      final list = <DailyChallenge>[];
      final result = DailyChallenges.applyIncrement(list, 'no_such', 1);
      expect(result.list, list);
      expect(result.justCompleted, isNull);
    });
  });

  group('XP reward shape', () {
    test('all template definitions provide a positive xpReward and target', () {
      for (final def in DailyChallenges.all) {
        expect(def.xpReward, greaterThan(0), reason: def.id);
        expect(def.target, greaterThan(0), reason: def.id);
        expect(def.title, isNotEmpty);
      }
    });
  });
}
