import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_detail_screen.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Wraps [LessonDetailScreen] in a [MaterialApp.router] with the minimum
/// GoRouter setup so `context.go()` calls don't throw.
Widget _buildTestWidget(String lessonId) {
  final router = GoRouter(
    initialLocation: '/lesson/$lessonId',
    routes: [
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) =>
            LessonDetailScreen(lessonId: state.pathParameters['id']!),
      ),
      // Dummy targets so context.go() doesn't assert.
      GoRoute(path: '/trainer', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/trainer/lesson/:id/play/:idx',
        builder: (_, __) => const SizedBox(),
      ),
    ],
  );

  return MaterialApp.router(
    theme: appTheme,
    routerConfig: router,
  );
}

void main() {
  group('LessonDetailScreen — invalid lesson', () {
    testWidgets('shows "Lesson not found" for unknown id', (tester) async {
      await tester.pumpWidget(_buildTestWidget('nonexistent_lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson not found'), findsOneWidget);
    });

    testWidgets('AppBar title is "Lesson" for unknown id', (tester) async {
      await tester.pumpWidget(_buildTestWidget('nonexistent_lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson'), findsOneWidget);
    });
  });

  group('LessonDetailScreen — drawing_hands lesson', () {
    final lesson =
        lessonsCatalog.firstWhere((l) => l.id == 'drawing_hands');

    testWidgets('AppBar shows lesson title', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.title), findsOneWidget);
    });

    testWidgets('displays "Overview" header in introduction card',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('displays lesson introduction text', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.introduction), findsOneWidget);
    });

    testWidgets('displays "Scenarios" section header', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text('Scenarios'), findsOneWidget);
    });

    testWidgets('renders a card for each scenario', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      for (final scenario in lesson.scenarios) {
        expect(find.text(scenario.title), findsOneWidget);
      }
    });

    testWidgets('scenario cards show numbered badges', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      for (var i = 0; i < lesson.scenarios.length; i++) {
        expect(find.text('${i + 1}'), findsOneWidget);
      }
    });

    testWidgets('scenario cards display game type labels', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      // drawing_hands has 3 Hold'em + 1 Omaha (PLO) scenario.
      final holdemCount = lesson.scenarios
          .where((s) => s.gameType == GameType.texasHoldem)
          .length;
      final ploCount = lesson.scenarios
          .where((s) => s.gameType == GameType.omaha)
          .length;

      expect(find.text("Hold'em"), findsNWidgets(holdemCount));
      expect(find.text('PLO'), findsNWidgets(ploCount));
    });

    testWidgets('each scenario card has a play arrow icon', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.play_arrow),
        findsNWidgets(lesson.scenarios.length),
      );
    });

    testWidgets('renders lesson icon from icon map', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('back button navigates to /trainer', (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      // Tap the back arrow.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // After navigation the detail screen is no longer visible.
      expect(find.text(lesson.title), findsNothing);
    });
  });

  group('LessonDetailScreen — hand_protection lesson', () {
    final lesson =
        lessonsCatalog.firstWhere((l) => l.id == 'hand_protection');

    testWidgets('renders correct number of scenarios', (tester) async {
      await tester.pumpWidget(_buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      for (final scenario in lesson.scenarios) {
        expect(find.text(scenario.title), findsOneWidget);
      }
      // 2 scenarios in hand_protection.
      expect(lesson.scenarios.length, 2);
    });

    testWidgets('all scenarios are Hold\'em (no PLO)', (tester) async {
      await tester.pumpWidget(_buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.text("Hold'em"), findsNWidgets(lesson.scenarios.length));
      expect(find.text('PLO'), findsNothing);
    });

    testWidgets('renders shield icon from icon map', (tester) async {
      await tester.pumpWidget(_buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('displays introduction text', (tester) async {
      await tester.pumpWidget(_buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.introduction), findsOneWidget);
    });
  });

  group('LessonDetailScreen — scenario descriptions', () {
    testWidgets('each scenario description is visible for drawing_hands',
        (tester) async {
      await tester.pumpWidget(_buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      final lesson =
          lessonsCatalog.firstWhere((l) => l.id == 'drawing_hands');
      for (final scenario in lesson.scenarios) {
        // Descriptions may be truncated (maxLines: 2) but the Text widget
        // with the full string is still in the tree.
        expect(
          find.text(scenario.description, skipOffstage: false),
          findsOneWidget,
        );
      }
    });
  });
}
