import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lessons_list_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _service() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> buildTestWidget() async {
    final service = await _service();
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

    testWidgets('shows a per-lesson scenario completion summary',
        (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      // With no mastery yet every lesson shows "0 / N scenario(s)".
      for (final lesson in lessonsCatalog) {
        final count = lesson.scenarios.length;
        final label =
            '0 / $count scenario${count > 1 ? 's' : ''}';
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('renders a Mastery summary header', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Mastery'), findsOneWidget);
    });

    testWidgets('renders lesson icons without errors', (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(Icon), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each lesson card has an InkWell for tap handling',
        (tester) async {
      await tester.pumpWidget(await buildTestWidget());
      await tester.pumpAndSettle();

      // One InkWell per lesson card; the summary header is non-tappable.
      expect(
        find.byType(InkWell),
        findsNWidgets(lessonsCatalog.length),
      );
    });
  });
}
