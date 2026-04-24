import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lessons_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> buildTestWidget() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final service = UserStatsService(prefs);
  return ProviderScope(
    overrides: [
      userStatsServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp(
      theme: appTheme,
      home: const Scaffold(body: LessonsListScreen()),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LessonsListScreen', () {
    testWidgets('renders a card for every lesson in the catalog',
        (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.title), findsOneWidget);
      }
    });

    testWidgets('displays correct subtitle for each lesson', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.subtitle), findsOneWidget);
      }
    });

    testWidgets('shows "0 / N scenarios" for a fresh user', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(
          find.text('0 / ${lesson.scenarios.length} scenarios'),
          findsOneWidget,
        );
      }
    });

    testWidgets('shows a difficulty badge for every lesson', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.difficulty.label), findsWidgets);
      }
    });

    testWidgets('shows chevron_right icon on each card', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.chevron_right_rounded),
        findsNWidgets(lessonsCatalog.length),
      );
    });

    testWidgets('each lesson card has an InkWell for tap handling',
        (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byType(InkWell),
        findsNWidgets(lessonsCatalog.length),
      );
    });
  });
}
