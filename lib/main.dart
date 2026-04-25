import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/scenario_mastery.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final statsService = await UserStatsService.create();
  runApp(
    ProviderScope(
      overrides: [
        userStatsServiceProvider.overrideWithValue(statsService),
        achievementEvaluatorProvider.overrideWithValue(_buildEvaluator()),
      ],
      child: const PokerTrainerApp(),
    ),
  );
}

/// Build an [AchievementEvaluator] seeded with the live lessons catalog.
AchievementEvaluator _buildEvaluator() {
  final keysByLesson = <String, List<String>>{};
  var total = 0;
  for (final lesson in lessonsCatalog) {
    final keys = <String>[];
    for (var i = 0; i < lesson.scenarios.length; i++) {
      keys.add(scenarioKeyFor(lesson.id, i));
    }
    keysByLesson[lesson.id] = keys;
    total += keys.length;
  }
  return AchievementEvaluator(
    totalScenarios: total,
    scenarioKeysByLesson: keysByLesson,
  );
}
