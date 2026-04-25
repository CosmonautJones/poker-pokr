import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/scenario_mastery.dart';

void main() {
  group('MasteryRecord.starsFor', () {
    test('zero completions = 0 stars', () {
      expect(
        MasteryRecord.starsFor(completions: 0, cleanCompletions: 0),
        0,
      );
    });

    test('any completion (with undo) = 1 star', () {
      expect(
        MasteryRecord.starsFor(completions: 1, cleanCompletions: 0),
        1,
      );
      expect(
        MasteryRecord.starsFor(completions: 5, cleanCompletions: 0),
        1,
      );
    });

    test('one or two clean completions = 2 stars', () {
      expect(
        MasteryRecord.starsFor(completions: 1, cleanCompletions: 1),
        2,
      );
      expect(
        MasteryRecord.starsFor(completions: 4, cleanCompletions: 2),
        2,
      );
    });

    test('three or more clean completions = 3 stars', () {
      expect(
        MasteryRecord.starsFor(completions: 3, cleanCompletions: 3),
        3,
      );
      expect(
        MasteryRecord.starsFor(completions: 10, cleanCompletions: 7),
        3,
      );
    });
  });

  group('MasteryRecord.recordCompletion', () {
    final now = DateTime(2026, 4, 25);

    test('first dirty completion → 1 star, lastPlayedDay set', () {
      final updated = const MasteryRecord.empty()
          .recordCompletion(clean: false, now: now);
      expect(updated.completions, 1);
      expect(updated.cleanCompletions, 0);
      expect(updated.bestStars, 1);
      expect(updated.lastPlayedDay, now);
    });

    test('first clean completion → 2 stars', () {
      final updated = const MasteryRecord.empty()
          .recordCompletion(clean: true, now: now);
      expect(updated.completions, 1);
      expect(updated.cleanCompletions, 1);
      expect(updated.bestStars, 2);
    });

    test('three clean completions → 3 stars', () {
      var rec = const MasteryRecord.empty();
      rec = rec.recordCompletion(clean: true, now: now);
      rec = rec.recordCompletion(clean: true, now: now);
      rec = rec.recordCompletion(clean: true, now: now);
      expect(rec.completions, 3);
      expect(rec.cleanCompletions, 3);
      expect(rec.bestStars, 3);
    });

    test('bestStars never regresses on a dirty replay', () {
      var rec = const MasteryRecord.empty();
      rec = rec.recordCompletion(clean: true, now: now);
      rec = rec.recordCompletion(clean: true, now: now);
      rec = rec.recordCompletion(clean: true, now: now);
      // 3 stars achieved. Now a dirty replay shouldn't lower it.
      rec = rec.recordCompletion(clean: false, now: now);
      expect(rec.bestStars, 3);
      expect(rec.completions, 4);
      expect(rec.cleanCompletions, 3);
    });
  });

  group('MasteryRecord JSON', () {
    test('roundtrip preserves all fields', () {
      final rec = MasteryRecord(
        completions: 4,
        cleanCompletions: 2,
        bestStars: 2,
        lastPlayedDay: DateTime(2026, 4, 25),
      );
      final back = MasteryRecord.fromJson(rec.toJson());
      expect(back.completions, 4);
      expect(back.cleanCompletions, 2);
      expect(back.bestStars, 2);
      expect(back.lastPlayedDay, DateTime(2026, 4, 25));
    });

    test('omits null lastPlayedDay from JSON', () {
      final rec = const MasteryRecord.empty();
      final json = rec.toJson();
      expect(json.containsKey('d'), isFalse);
    });

    test('decode tolerates missing fields', () {
      final rec = MasteryRecord.fromJson(<String, dynamic>{});
      expect(rec.completions, 0);
      expect(rec.cleanCompletions, 0);
      expect(rec.bestStars, 0);
      expect(rec.lastPlayedDay, isNull);
    });
  });

  group('scenarioKeyFor', () {
    test('produces stable lessonId/index strings', () {
      expect(scenarioKeyFor('drawing_hands', 0), 'drawing_hands/0');
      expect(scenarioKeyFor('hand_protection', 2), 'hand_protection/2');
    });
  });
}
