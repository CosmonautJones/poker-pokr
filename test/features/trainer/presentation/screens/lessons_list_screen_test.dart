import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lessons_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _stubService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

Future<Widget> _buildTestWidget() async {
  final service = await _stubService();
  return ProviderScope(
    overrides: [userStatsServiceProvider.overrideWithValue(service)],
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
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.title), findsOneWidget);
      }
    });

    testWidgets('displays correct subtitle for each lesson', (tester) async {
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.subtitle), findsOneWidget);
      }
    });

    testWidgets('shows initial scenario count when nothing is complete',
        (tester) async {
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        final count = lesson.scenarios.length;
        final label = '$count scenario${count > 1 ? "s" : ""}';
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('shows chevron_right icon on each card', (tester) async {
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.chevron_right_rounded),
        findsNWidgets(lessonsCatalog.length),
      );
    });

    testWidgets('renders without exceptions', (tester) async {
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each lesson card has an InkWell for tap handling',
        (tester) async {
      await tester.pumpWidget(await _buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byType(InkWell),
        findsNWidgets(lessonsCatalog.length),
      );
    });
  });
}
