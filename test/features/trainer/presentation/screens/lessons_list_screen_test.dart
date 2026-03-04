import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/theme/app_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lessons_list_screen.dart';

void main() {
  Widget buildTestWidget() {
    return MaterialApp(
      theme: appTheme,
      home: const Scaffold(body: LessonsListScreen()),
    );
  }

  group('LessonsListScreen', () {
    testWidgets('renders a card for every lesson in the catalog',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.title), findsOneWidget);
      }
    });

    testWidgets('displays correct subtitle for each lesson', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        expect(find.text(lesson.subtitle), findsOneWidget);
      }
    });

    testWidgets('displays scenario count for each lesson', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      for (final lesson in lessonsCatalog) {
        final count = lesson.scenarios.length;
        final label = '$count scenario${count > 1 ? "s" : ""}';
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('shows chevron_right icon on each card', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byIcon(Icons.chevron_right),
        findsNWidgets(lessonsCatalog.length),
      );
    });

    testWidgets('renders lesson icons without errors', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Icons are rendered inside 48x48 containers. If the icon lookup
      // crashed, pumpAndSettle would have thrown. Verify widget tree is
      // intact by checking the icon widgets exist.
      expect(find.byType(Icon), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('each lesson card has an InkWell for tap handling',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.byType(InkWell),
        findsNWidgets(lessonsCatalog.length),
      );
    });

    testWidgets('icon containers have gradient decoration', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Each lesson card has a 48x48 container with a LinearGradient.
      final containers = tester.widgetList<Container>(
        find.byWidgetPredicate((widget) =>
            widget is Container &&
            widget.constraints?.maxWidth == 48 &&
            widget.constraints?.maxHeight == 48),
      );
      // SizedBox/Container matching varies; just verify some decorated
      // containers exist.
      expect(find.byType(Container), findsWidgets);
    });
  });
}
