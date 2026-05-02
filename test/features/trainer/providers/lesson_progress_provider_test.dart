import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/features/trainer/providers/lesson_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LessonProgressNotifier', () {
    test('starts empty', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final state = container.read(lessonProgressProvider);
      expect(state.totalScenariosCompleted, 0);
    });

    test('markScenarioComplete returns true on first completion', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(lessonProgressProvider.notifier);
      final first = await notifier.markScenarioComplete(
        lessonId: 'drawing_hands',
        scenarioIndex: 0,
        now: DateTime(2026, 4, 19),
      );
      expect(first, isTrue);
      expect(
        container.read(lessonProgressProvider).isComplete('drawing_hands', 0),
        isTrue,
      );
    });

    test('markScenarioComplete returns false on replay', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(lessonProgressProvider.notifier);
      await notifier.markScenarioComplete(
        lessonId: 'drawing_hands',
        scenarioIndex: 0,
        now: DateTime(2026, 4, 19),
      );
      final second = await notifier.markScenarioComplete(
        lessonId: 'drawing_hands',
        scenarioIndex: 0,
        now: DateTime(2026, 4, 20),
      );
      expect(second, isFalse);
      // Original timestamp preserved.
      expect(
        container
            .read(lessonProgressProvider)
            .completedAt('drawing_hands', 0),
        DateTime(2026, 4, 19),
      );
    });

    test('progress persists across container rebuilds', () async {
      final service = await _freshService();
      final container1 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      await container1.read(lessonProgressProvider.notifier).markScenarioComplete(
            lessonId: 'drawing_hands',
            scenarioIndex: 2,
            now: DateTime(2026, 4, 19),
          );
      container1.dispose();

      final container2 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container2.dispose);
      final state = container2.read(lessonProgressProvider);
      expect(state.isComplete('drawing_hands', 2), isTrue);
    });

    test('resetAll clears progress', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(lessonProgressProvider.notifier);
      await notifier.markScenarioComplete(
        lessonId: 'drawing_hands',
        scenarioIndex: 0,
      );
      await notifier.resetAll();
      expect(
        container.read(lessonProgressProvider).totalScenariosCompleted,
        0,
      );
    });
  });
}
