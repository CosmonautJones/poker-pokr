import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/poker/history/state_history.dart';

void main() {
  group('StateHistory', () {
    group('push', () {
      test('adds state and advances current', () {
        final history = StateHistory<int>(0);
        expect(history.current, 0);
        expect(history.length, 1);

        history.push(1);
        expect(history.current, 1);
        expect(history.length, 2);

        history.push(2);
        expect(history.current, 2);
        expect(history.length, 3);
      });

      test('currentIndex reflects latest push', () {
        final history = StateHistory<int>(0);
        expect(history.currentIndex, 0);

        history.push(1);
        expect(history.currentIndex, 1);

        history.push(2);
        expect(history.currentIndex, 2);
      });
    });

    group('undo', () {
      test('returns previous state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        final result = history.undo();
        expect(result, 1);
        expect(history.current, 1);
      });

      test('returns null when at beginning', () {
        final history = StateHistory<int>(0);
        final result = history.undo();
        expect(result, isNull);
        expect(history.current, 0);
      });

      test('can undo multiple times to initial state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        expect(history.undo(), 2);
        expect(history.undo(), 1);
        expect(history.undo(), 0);
        expect(history.undo(), isNull); // already at beginning
        expect(history.current, 0);
      });
    });

    group('redo', () {
      test('returns next state after undo', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        history.undo(); // back to 1
        final result = history.redo();
        expect(result, 2);
        expect(history.current, 2);
      });

      test('returns null when at end (no redo available)', () {
        final history = StateHistory<int>(0);
        history.push(1);

        final result = history.redo();
        expect(result, isNull);
        expect(history.current, 1);
      });

      test('can redo multiple undos', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        history.undo(); // 2
        history.undo(); // 1
        history.undo(); // 0

        expect(history.redo(), 1);
        expect(history.redo(), 2);
        expect(history.redo(), 3);
        expect(history.redo(), isNull); // at end
      });
    });

    group('push after undo truncates redo stack', () {
      test('truncates future states when pushing after undo', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        // Undo to state 1
        history.undo(); // 2
        history.undo(); // 1

        // Push a new state - should discard 2 and 3
        history.push(10);

        expect(history.current, 10);
        expect(history.length, 3); // [0, 1, 10]
        expect(history.canRedo, false);
      });

      test('redo is not available after push following undo', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        history.undo(); // back to 1
        history.push(5); // replaces 2

        expect(history.canRedo, false);
        expect(history.redo(), isNull);
        expect(history.current, 5);
      });

      test('states list reflects truncation', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        history.undo(); // 2
        history.undo(); // 1
        history.push(99);

        expect(history.states, [0, 1, 99]);
      });
    });

    group('canUndo / canRedo', () {
      test('canUndo is false for fresh history', () {
        final history = StateHistory<int>(0);
        expect(history.canUndo, false);
      });

      test('canUndo is true after push', () {
        final history = StateHistory<int>(0);
        history.push(1);
        expect(history.canUndo, true);
      });

      test('canRedo is false when at latest state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        expect(history.canRedo, false);
      });

      test('canRedo is true after undo', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.undo();
        expect(history.canRedo, true);
      });

      test('canUndo is false after undoing to initial state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.undo();
        expect(history.canUndo, false);
      });

      test('canRedo is false after redoing to latest state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.undo();
        history.redo();
        expect(history.canRedo, false);
      });
    });

    group('forkAt', () {
      test('creates a new history truncated at index', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        final forked = history.forkAt(1);
        expect(forked.length, 2); // [0, 1]
        expect(forked.current, 1);
        expect(forked.currentIndex, 1);
        expect(forked.states, [0, 1]);
      });

      test('forked history is independent of original', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        final forked = history.forkAt(1);
        forked.push(99);

        // Original should be unaffected
        expect(history.length, 3);
        expect(history.states, [0, 1, 2]);

        // Forked should have the new state
        expect(forked.length, 3);
        expect(forked.states, [0, 1, 99]);
      });

      test('forkAt(0) creates history with just the initial state', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        final forked = history.forkAt(0);
        expect(forked.length, 1);
        expect(forked.current, 0);
        expect(forked.canUndo, false);
        expect(forked.canRedo, false);
      });

      test('forkAt last index creates a full copy', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        final forked = history.forkAt(2);
        expect(forked.length, 3);
        expect(forked.states, [0, 1, 2]);
        expect(forked.current, 2);
      });

      test('forkAt throws for out-of-range index', () {
        final history = StateHistory<int>(0);
        history.push(1);

        expect(() => history.forkAt(-1), throwsA(isA<RangeError>()));
        expect(() => history.forkAt(2), throwsA(isA<RangeError>()));
      });

      test('forkAt can be further modified with undo/redo/push', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);
        history.push(3);

        final forked = history.forkAt(2);
        // forked has [0, 1, 2], current = 2

        forked.undo(); // current = 1
        expect(forked.current, 1);
        expect(forked.canRedo, true);

        forked.redo(); // current = 2
        expect(forked.current, 2);

        forked.push(42);
        expect(forked.states, [0, 1, 2, 42]);
      });
    });

    group('states list', () {
      test('returns unmodifiable view', () {
        final history = StateHistory<int>(0);
        history.push(1);

        final states = history.states;
        expect(() => (states as List).add(99), throwsUnsupportedError);
      });
    });

    group('toString', () {
      test('includes length and currentIndex', () {
        final history = StateHistory<int>(0);
        history.push(1);
        history.push(2);

        final str = history.toString();
        expect(str, contains('length: 3'));
        expect(str, contains('currentIndex: 2'));
      });
    });
  });
}
