import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_detail_screen.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _service() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

/// Wraps [LessonDetailScreen] in a [ProviderScope] + [MaterialApp.router]
/// with the minimum GoRouter setup so `context.go()` calls don't throw.
Future<Widget> _buildTestWidget(String lessonId) async {
  final service = await _service();
  final router = GoRouter(
    initialLocation: '/lesson/$lessonId',
    routes: [
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) =>
            LessonDetailScreen(lessonId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/trainer', builder: (_, __) => const SizedBox()),
      GoRoute(
        path: '/trainer/lesson/:id/play/:idx',
        builder: (_, __) => const SizedBox(),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      userStatsServiceProvider.overrideWithValue(service),
    ],
    child: MaterialApp.router(theme: appTheme, routerConfig: router),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LessonDetailScreen — invalid lesson', () {
    testWidgets('shows "Lesson not found" for unknown id', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('nonexistent_lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson not found'), findsOneWidget);
    });

    testWidgets('AppBar title is "Lesson" for unknown id', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('nonexistent_lesson'));
      await tester.pumpAndSettle();

      expect(find.text('Lesson'), findsOneWidget);
    });
  });

  group('LessonDetailScreen — drawing_hands lesson', () {
    final lesson =
        lessonsCatalog.firstWhere((l) => l.id == 'drawing_hands');

    testWidgets('AppBar shows lesson title', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.title), findsOneWidget);
    });

    testWidgets('displays "Overview" header in introduction card',
        (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
    });

    testWidgets('displays lesson introduction text', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.introduction), findsOneWidget);
    });

    testWidgets('displays "Scenarios" section header', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.text('Scenarios'), findsOneWidget);
    });

    testWidgets('renders a card for each scenario', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      for (final scenario in lesson.scenarios) {
        expect(find.text(scenario.title), findsOneWidget);
      }
    });

    testWidgets('scenario cards show numbered badges', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      for (var i = 0; i < lesson.scenarios.length; i++) {
        expect(find.text('${i + 1}'), findsOneWidget);
      }
    });

    testWidgets('scenario cards display game type labels', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

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
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.play_arrow),
        findsNWidgets(lesson.scenarios.length),
      );
    });

    testWidgets('shows "Not started" hint for unplayed scenarios',
        (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      // Every scenario starts un-played → mastery hint reads "Not started".
      expect(
        find.text('Not started'),
        findsNWidgets(lesson.scenarios.length),
      );
    });

    testWidgets('renders lesson icon from icon map', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('back button navigates to /trainer', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text(lesson.title), findsNothing);
    });
  });

  group('LessonDetailScreen — hand_protection lesson', () {
    final lesson =
        lessonsCatalog.firstWhere((l) => l.id == 'hand_protection');

    testWidgets('renders correct number of scenarios', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      for (final scenario in lesson.scenarios) {
        expect(find.text(scenario.title), findsOneWidget);
      }
      expect(lesson.scenarios.length, 2);
    });

    testWidgets('all scenarios are Hold\'em (no PLO)', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.text("Hold'em"), findsNWidgets(lesson.scenarios.length));
      expect(find.text('PLO'), findsNothing);
    });

    testWidgets('renders shield icon from icon map', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.shield), findsOneWidget);
    });

    testWidgets('displays introduction text', (tester) async {
      await tester.pumpWidget(await _buildTestWidget('hand_protection'));
      await tester.pumpAndSettle();

      expect(find.text(lesson.introduction), findsOneWidget);
    });
  });

  group('LessonDetailScreen — scenario descriptions', () {
    testWidgets('each scenario description is visible for drawing_hands',
        (tester) async {
      await tester.pumpWidget(await _buildTestWidget('drawing_hands'));
      await tester.pumpAndSettle();

      final lesson =
          lessonsCatalog.firstWhere((l) => l.id == 'drawing_hands');
      for (final scenario in lesson.scenarios) {
        expect(
          find.text(scenario.description, skipOffstage: false),
          findsOneWidget,
        );
      }
    });
  });
}
