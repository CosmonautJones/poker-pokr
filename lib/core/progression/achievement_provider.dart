import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/haptic_service.dart';
import 'achievement.dart';
import 'achievement_engine.dart';
import 'achievement_service.dart';
import 'progression_provider.dart';
import 'user_stats.dart';

/// Public state surfaced to UI. Immutable; replaced by the notifier on each
/// change so Riverpod can diff.
class AchievementState {
  /// Full set of achievement ids currently unlocked.
  final Set<String> unlockedIds;

  /// FIFO queue of achievements that have unlocked but not yet been shown
  /// in the celebration banner. UI consumers call
  /// [AchievementNotifier.consumeNextToast] once the banner finishes
  /// playing.
  final Queue<Achievement> pendingToasts;

  const AchievementState({
    required this.unlockedIds,
    required this.pendingToasts,
  });

  AchievementState copyWith({
    Set<String>? unlockedIds,
    Queue<Achievement>? pendingToasts,
  }) {
    return AchievementState(
      unlockedIds: unlockedIds ?? this.unlockedIds,
      pendingToasts: pendingToasts ?? this.pendingToasts,
    );
  }
}

/// Singleton provider for the SharedPreferences-backed service.
///
/// Overridden in `main()` with a concrete instance once SharedPreferences
/// has been initialized; tests provide their own override.
final achievementServiceProvider = Provider<AchievementService>((ref) {
  throw UnimplementedError(
    'achievementServiceProvider must be overridden with an '
    'AchievementService instance (see main.dart).',
  );
});

/// Live achievements snapshot. Listens to [userStatsProvider]; on every
/// stats change, runs the engine, persists new unlocks, and enqueues any
/// freshly-unlocked badges for the celebration banner.
final achievementsProvider =
    NotifierProvider<AchievementNotifier, AchievementState>(
  AchievementNotifier.new,
);

class AchievementNotifier extends Notifier<AchievementState> {
  @override
  AchievementState build() {
    final service = ref.read(achievementServiceProvider);
    final stored = service.loadUnlocked();

    // Reconcile the stored set against current stats so a user who already
    // crossed a threshold (e.g. before this version shipped) gets credited
    // without firing a toast.
    final initialStats = ref.read(userStatsProvider);
    final reconciled = AchievementEngine.evaluate(initialStats, stored);
    if (reconciled.unlocked.length != stored.length) {
      // Persist silently — no toasts for retroactive unlocks.
      // Fire-and-forget; the in-memory state is the source of truth for the
      // current frame.
      service.saveUnlocked(reconciled.unlocked);
    }

    // Re-evaluate on every stats change. Using ref.listen so we skip the
    // initial fire and only react to mutations.
    ref.listen<UserStats>(userStatsProvider, (prev, next) {
      _onStatsChanged(next);
    });

    return AchievementState(
      unlockedIds: reconciled.unlocked,
      pendingToasts: Queue<Achievement>(),
    );
  }

  void _onStatsChanged(UserStats stats) {
    final result = AchievementEngine.evaluate(stats, state.unlockedIds);
    if (result.justUnlocked.isEmpty) return;

    final nextQueue = Queue<Achievement>.from(state.pendingToasts)
      ..addAll(result.justUnlocked);
    state = AchievementState(
      unlockedIds: result.unlocked,
      pendingToasts: nextQueue,
    );

    // Persist — fire-and-forget. SharedPreferences serializes writes.
    ref.read(achievementServiceProvider).saveUnlocked(result.unlocked);

    // Celebration haptic.
    ref.read(hapticServiceProvider).success();
  }

  /// Pop the next pending toast (or null if none). Use this from the
  /// banner after its dismiss animation finishes.
  Achievement? consumeNextToast() {
    if (state.pendingToasts.isEmpty) return null;
    final next = Queue<Achievement>.from(state.pendingToasts);
    final achievement = next.removeFirst();
    state = state.copyWith(pendingToasts: next);
    return achievement;
  }

  /// Peek without removing. Useful for the banner UI to decide whether to
  /// be visible.
  Achievement? peekNextToast() {
    if (state.pendingToasts.isEmpty) return null;
    return state.pendingToasts.first;
  }

  /// Clear the entire toast queue without showing them. Used when the user
  /// explicitly opens the badges screen.
  void clearPendingToasts() {
    if (state.pendingToasts.isEmpty) return;
    state = state.copyWith(pendingToasts: Queue<Achievement>());
  }
}
