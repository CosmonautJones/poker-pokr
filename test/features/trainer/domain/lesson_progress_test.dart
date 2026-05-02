import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';

void main() {
  group('LessonProgress — empty state', () {
    test('empty has no completions', () {
      final p = LessonProgress.empty();
      expect(p.totalScenariosCompleted, 0);
      expect(p.completedCount('drawing_hands'), 0);
      expect(p.isComplete('drawing_hands', 0), isFalse);
      expect(p.completedAt('drawing_hands', 0), isNull);
      expect(p.completedLessonIds, isEmpty);
    });
  });

  group('LessonProgress — markComplete', () {
    final ts1 = DateTime(2026, 1, 1, 9, 0);
    final ts2 = DateTime(2026, 1, 2, 10, 0);

    test('marking a scenario records timestamp', () {
      final p = LessonProgress.empty().markComplete('foo', 0, ts1);
      expect(p.isComplete('foo', 0), isTrue);
      expect(p.completedCount('foo'), 1);
      expect(p.completedAt('foo', 0), ts1);
    });

    test('marking the same scenario twice keeps the original timestamp', () {
      final p = LessonProgress.empty()
          .markComplete('foo', 0, ts1)
          .markComplete('foo', 0, ts2);
      expect(p.completedAt('foo', 0), ts1);
      expect(p.completedCount('foo'), 1);
    });

    test('marking different scenarios accumulates', () {
      final p = LessonProgress.empty()
          .markComplete('foo', 0, ts1)
          .markComplete('foo', 2, ts2);
      expect(p.completedCount('foo'), 2);
      expect(p.isComplete('foo', 0), isTrue);
      expect(p.isComplete('foo', 1), isFalse);
      expect(p.isComplete('foo', 2), isTrue);
      expect(p.totalScenariosCompleted, 2);
    });

    test('marking is immutable - returns new instance', () {
      final original = LessonProgress.empty();
      final updated = original.markComplete('foo', 0, ts1);
      expect(original.isComplete('foo', 0), isFalse);
      expect(updated.isComplete('foo', 0), isTrue);
    });

    test('totalScenariosCompleted spans lessons', () {
      final p = LessonProgress.empty()
          .markComplete('a', 0, ts1)
          .markComplete('a', 1, ts1)
          .markComplete('b', 0, ts2);
      expect(p.totalScenariosCompleted, 3);
      expect(p.completedLessonIds.toSet(), {'a', 'b'});
    });
  });

  group('LessonProgress — encode/decode roundtrip', () {
    test('preserves scenario timestamps across multiple lessons', () {
      final ts = DateTime(2026, 4, 19, 12, 30);
      final p = LessonProgress.empty()
          .markComplete('drawing_hands', 0, ts)
          .markComplete('drawing_hands', 3, ts)
          .markComplete('hand_protection', 1, ts);
      final raw = p.encode();
      final decoded = LessonProgress.tryDecode(raw)!;
      expect(decoded.isComplete('drawing_hands', 0), isTrue);
      expect(decoded.isComplete('drawing_hands', 3), isTrue);
      expect(decoded.isComplete('hand_protection', 1), isTrue);
      expect(decoded.completedAt('drawing_hands', 0), ts);
      expect(decoded.totalScenariosCompleted, 3);
    });

    test('tryDecode handles null and empty', () {
      expect(LessonProgress.tryDecode(null), isNull);
      expect(LessonProgress.tryDecode(''), isNull);
    });

    test('tryDecode returns null for non-JSON garbage', () {
      expect(LessonProgress.tryDecode('not json'), isNull);
    });

    test('tryDecode skips malformed inner entries but keeps valid ones', () {
      const raw = '{"good":{"0":"2026-01-01T00:00:00.000",'
          '"bad":"oops","1":"not-a-date"},"empty":{}}';
      final decoded = LessonProgress.tryDecode(raw);
      expect(decoded, isNotNull);
      expect(decoded!.isComplete('good', 0), isTrue);
      // 'bad' and '1' (with unparseable timestamp) are dropped.
      expect(decoded.completedCount('good'), 1);
      expect(decoded.completedLessonIds.contains('empty'), isFalse);
    });
  });

  group('LessonProgress.fromMap', () {
    test('drops empty lesson maps', () {
      final p = LessonProgress.fromMap({
        'a': {0: DateTime(2026, 1, 1)},
        'b': <int, DateTime>{},
      });
      expect(p.completedLessonIds.toList(), ['a']);
    });
  });
}
