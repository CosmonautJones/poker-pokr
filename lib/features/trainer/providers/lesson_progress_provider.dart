import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';

/// Live snapshot of lesson scenario completions. Rebuilds when
/// [markScenarioComplete] / [resetAll] mutate state.
final lessonProgressProvider =
    NotifierProvider<LessonProgressNotifier, LessonProgress>(
  LessonProgressNotifier.new,
);

class LessonProgressNotifier extends Notifier<LessonProgress> {
  @override
  LessonProgress build() =>
      ref.read(userStatsServiceProvider).loadLessonProgress();

  /// Record a scenario completion. Returns `true` if this was the first
  /// time the scenario was completed (so the caller can decide whether to
  /// award full XP / show a celebration).
  Future<bool> markScenarioComplete({
    required String lessonId,
    required int scenarioIndex,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    if (state.isComplete(lessonId, scenarioIndex)) return false;

    final updated = state.markComplete(lessonId, scenarioIndex, ts);
    state = updated;
    await ref.read(userStatsServiceProvider).saveLessonProgress(updated);
    return true;
  }

  /// Wipe lesson progress entirely. Used by Settings → Reset progression.
  Future<void> resetAll() async {
    state = LessonProgress.empty();
    await ref.read(userStatsServiceProvider).clearLessonProgress();
  }
}
