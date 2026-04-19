import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/app.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final statsService = UserStatsService(prefs);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userStatsServiceProvider.overrideWithValue(statsService),
        ],
        child: const PokerTrainerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TableSense'), findsOneWidget);
  });
}
