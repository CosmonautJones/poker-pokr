import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';
import 'package:poker_trainer/core/progression/achievement_provider.dart';
import 'package:poker_trainer/core/progression/achievement_service.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  final statsService = await UserStatsService.create();
  final achievementService = await AchievementService.create();
  runApp(
    ProviderScope(
      overrides: [
        userStatsServiceProvider.overrideWithValue(statsService),
        achievementServiceProvider.overrideWithValue(achievementService),
      ],
      child: const PokerTrainerApp(),
    ),
  );
}
