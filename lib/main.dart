import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/achievements_service.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  // Single SharedPreferences instance shared by both services so reads stay
  // consistent and we don't pay the init cost twice.
  final prefs = await SharedPreferences.getInstance();
  final statsService = UserStatsService(prefs);
  final achievementsService = AchievementsService(prefs);
  runApp(
    ProviderScope(
      overrides: [
        userStatsServiceProvider.overrideWithValue(statsService),
        achievementsServiceProvider.overrideWithValue(achievementsService),
      ],
      child: const PokerTrainerApp(),
    ),
  );
}
