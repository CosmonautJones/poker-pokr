import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/app_version.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Settings shows the version from app_version.dart',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsServiceProvider.overrideWithValue(UserStatsService(prefs)),
        ],
        child: MaterialApp(theme: appTheme, home: const SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TableSense $appVersionLabel'), findsOneWidget);

    final footer = find.text('Version $appVersion ($appBuild)');
    await tester.scrollUntilVisible(footer, 200);
    expect(footer, findsOneWidget);
    expect(find.textContaining('1.0.0'), findsNothing);
  });
}
