import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

ProviderContainer _container(
  UserStatsService service, {
  AchievementEvaluator? evaluator,
}) {
  return ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(service),
    if (evaluator != null)
      achievementEvaluatorProvider.overrideWithValue(evaluator),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const liveEvaluator = AchievementEvaluator(
    totalScenarios: 2,
    scenarioKeysByLesson: {
      'drawing_hands': ['drawing_hands/0', 'drawing_hands/1'],
    },
  );

  group('UserStatsNotifier with live evaluator', () {
    test('first hand unlocks firstHand and awards bonus XP', () async {
      final service = await _freshService();
      final container = _container(service, evaluator: liveEvaluator);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 25));

      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievementIds, contains('firstHand'));
      // Base hand XP + daily bonus + achievement bonus.
      expect(
        stats.totalXp,
        Progression.xpPerHand +
            Progression.xpDailyBonus +
            Progression.xpPerAchievement,
      );
    });

    test('toast queue receives the new unlocks', () async {
      final service = await _freshService();
      final container = _container(service, evaluator: liveEvaluator);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 25));

      final pending = container.read(pendingAchievementsProvider);
      expect(pending, contains(AchievementId.firstHand));
      // dismissHead removes the head only.
      container.read(pendingAchievementsProvider.notifier).dismissHead();
      final after = container.read(pendingAchievementsProvider);
      expect(after.contains(AchievementId.firstHand), isFalse);
    });

    test(
        'recordLessonComplete with clean attempt updates mastery and stars',
        () async {
      final service = await _freshService();
      final container = _container(service, evaluator: liveEvaluator);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordLessonComplete(
        scenarioKey: 'drawing_hands/0',
        undoUsed: false,
        now: DateTime(2026, 4, 25),
      );

      final stats = container.read(userStatsProvider);
      final rec = stats.scenarioMastery['drawing_hands/0']!;
      expect(rec.completions, 1);
      expect(rec.cleanCompletions, 1);
      expect(rec.bestStars, 2);
      // Lesson XP + daily bonus + first-time star tier bonus * 2 (1→2).
      // Achievements: scholar unlocks for 1 lesson + perfectionist requires 3
      // stars → only scholar fires.
      expect(stats.unlockedAchievementIds, contains('scholar'));
      expect(stats.unlockedAchievementIds, isNot(contains('perfectionist')));
    });

    test('three clean completions unlock perfectionist', () async {
      final service = await _freshService();
      final container = _container(service, evaluator: liveEvaluator);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      for (var i = 0; i < 3; i++) {
        await notifier.recordLessonComplete(
          scenarioKey: 'drawing_hands/0',
          undoUsed: false,
          now: DateTime(2026, 4, 25 + i),
        );
      }
      final stats = container.read(userStatsProvider);
      final rec = stats.scenarioMastery['drawing_hands/0']!;
      expect(rec.bestStars, 3);
      expect(stats.unlockedAchievementIds, contains('perfectionist'));
    });

    test('disabled evaluator (default) does not award achievement XP',
        () async {
      final service = await _freshService();
      // No evaluator override → uses the default disabled instance.
      final container = _container(service);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 25));

      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievementIds, isEmpty);
      expect(
        stats.totalXp,
        Progression.xpPerHand + Progression.xpDailyBonus,
      );
    });
  });
}
