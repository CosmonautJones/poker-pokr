import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';

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
      ],
      child: const PokerTrainerApp(),
    ),
  );
}
