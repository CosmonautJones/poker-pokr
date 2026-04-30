import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'achievements_service.dart';
import 'progression_provider.dart';
import 'user_stats.dart';

/// Singleton provider for the SharedPreferences-backed achievements service.
/// Overridden in `main()` once SharedPreferences has initialized; tests can
/// override with an in-memory stub.
final achievementsServiceProvider = Provider<AchievementsService>((ref) {
  throw UnimplementedError(
    'achievementsServiceProvider must be overridden with an '
    'AchievementsService instance (see main.dart).',
  );
});

/// Live unlocked-achievement state. Recomputes whenever userStats changes,
/// awarding any newly-eligible achievements and queuing them for the unlock
/// overlay.
final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementsState>(
  AchievementsNotifier.new,
);

/// The next un-displayed unlock id, if any. The unlock overlay watches this
/// and consumes via [AchievementsNotifier.consumeNextPending].
final pendingUnlockProvider = Provider<String?>((ref) {
  final notifier = ref.watch(achievementsProvider.notifier);
  return notifier.peekPending();
});

class AchievementsNotifier extends Notifier<AchievementsState> {
  final Queue<String> _pending = Queue<String>();

  @override
  AchievementsState build() {
    final service = ref.read(achievementsServiceProvider);
    final initial = service.load();

    // Cold-start backfill: stamp anything already eligible at boot but skip
    // the toast queue — players shouldn't see celebrations for events that
    // happened in a previous session.
    final stats = ref.read(userStatsProvider);
    final backfill = initial.evaluateNew(stats);
    final state = backfill.isEmpty
        ? initial
        : initial.withUnlocked(backfill, DateTime.now());
    if (backfill.isNotEmpty) {
      service.save(state);
    }

    ref.listen<UserStats>(userStatsProvider, (previous, next) {
      _checkForUnlocks();
    });

    return state;
  }

  void _checkForUnlocks() {
    final stats = ref.read(userStatsProvider);
    final newly = state.evaluateNew(stats);
    if (newly.isEmpty) return;
    final now = DateTime.now();
    final next = state.withUnlocked(newly, now);
    state = next;
    _pending.addAll(newly);
    ref.read(achievementsServiceProvider).save(next);
    // pendingUnlockProvider reads the queue head off the notifier instance —
    // its value isn't derived from state, so we explicitly invalidate to
    // notify listeners (the unlock toast host). Safe inside listen callbacks
    // since invalidation schedules the recompute on the next microtask.
    ref.invalidate(pendingUnlockProvider);
  }

  /// Peek at the next id awaiting display without dequeuing it.
  String? peekPending() => _pending.isEmpty ? null : _pending.first;

  /// Pop the head of the pending queue. Called by the unlock overlay once it
  /// has finished animating one toast and is ready for the next.
  String? consumeNextPending() {
    if (_pending.isEmpty) return null;
    final id = _pending.removeFirst();
    ref.invalidate(pendingUnlockProvider);
    return id;
  }

  /// Reset all unlocks. Used by Settings → Reset progression.
  Future<void> resetAll() async {
    _pending.clear();
    state = const AchievementsState.empty();
    await ref.read(achievementsServiceProvider).save(state);
    ref.invalidate(pendingUnlockProvider);
  }
}
