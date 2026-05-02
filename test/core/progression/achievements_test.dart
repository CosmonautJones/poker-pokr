import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';
import 'package:poker_trainer/poker/models/card.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Build a minimal Lesson with the given id and number of scenarios.
/// We don't actually play the scenarios in these tests — only the count
/// matters for chapter-completion logic.
Lesson _lesson(String id, int scenarioCount) {
  // Cards are only used to satisfy the constructor; never inspected.
  final card = PokerCard.from(Rank.two, Suit.clubs);
  final scenarios = List<LessonScenario>.generate(
    scenarioCount,
    (i) => LessonScenario(
      title: 'S$i',
      description: '',
      heroIndex: 0,
      holeCards: const [],
      flopCards: [card, card, card],
      turnCard: card,
      riverCard: card,
      playerCount: 2,
      smallBlind: 1,
      bigBlind: 2,
      stacks: const [200, 200],
      dealerIndex: 0,
      gameType: GameType.texasHoldem,
      tips: const [],
      playerNames: const ['A', 'B'],
    ),
  );
  return Lesson(
    id: id,
    title: id,
    subtitle: '',
    introduction: '',
    iconCodePoint: 0xe87d,
    scenarios: scenarios,
  );
}

void main() {
  group('AchievementsEngine — empty state', () {
    test('no progress unlocks nothing', () {
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty(),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result, isEmpty);
    });

    test('empty lesson catalog does not unlock all_lessons trivially', () {
      // Guard against the off-by-one where "all lessons complete" with zero
      // lessons would be vacuously true.
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty(),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.contains('all_lessons'), isFalse);
    });
  });

  group('AchievementsEngine — hands milestones', () {
    test('one hand unlocks first_hand only', () {
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty().copyWith(handsPlayed: 1),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result, {'first_hand'});
    });

    test('100 hands unlocks all hand-count tiers', () {
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty().copyWith(handsPlayed: 100),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.containsAll({
        'first_hand',
        'ten_hands',
        'fifty_hands',
        'hundred_hands',
      }), isTrue);
    });
  });

  group('AchievementsEngine — streak milestones', () {
    test('streak_7 unlocks at 7 days even after streak resets', () {
      // Simulate a player whose current streak is 1 (just resumed) but
      // who peaked at 7. Achievements should be sticky on best-streak.
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty()
            .copyWith(streakDays: 1, bestStreakDays: 7),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.contains('streak_3'), isTrue);
      expect(result.contains('streak_7'), isTrue);
      expect(result.contains('streak_30'), isFalse);
    });

    test('streak_3 not unlocked at 2 days', () {
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty()
            .copyWith(streakDays: 2, bestStreakDays: 2),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.contains('streak_3'), isFalse);
    });
  });

  group('AchievementsEngine — lesson mastery', () {
    final lessons = [_lesson('a', 2), _lesson('b', 3)];

    test('one scenario unlocks first_lesson only', () {
      final progress =
          LessonProgress.empty().markComplete('a', 0, DateTime(2026));
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty(),
        lessonProgress: progress,
        lessons: lessons,
      );
      expect(result.contains('first_lesson'), isTrue);
      expect(result.contains('lesson_chapter'), isFalse);
      expect(result.contains('all_lessons'), isFalse);
    });

    test('finishing one full lesson unlocks lesson_chapter', () {
      final progress = LessonProgress.empty()
          .markComplete('a', 0, DateTime(2026))
          .markComplete('a', 1, DateTime(2026));
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty(),
        lessonProgress: progress,
        lessons: lessons,
      );
      expect(result.contains('lesson_chapter'), isTrue);
      expect(result.contains('all_lessons'), isFalse);
    });

    test('finishing every lesson unlocks all_lessons', () {
      var progress = LessonProgress.empty();
      for (final lesson in lessons) {
        for (var i = 0; i < lesson.scenarios.length; i++) {
          progress = progress.markComplete(lesson.id, i, DateTime(2026));
        }
      }
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty(),
        lessonProgress: progress,
        lessons: lessons,
      );
      expect(result.contains('all_lessons'), isTrue);
      expect(result.contains('lesson_chapter'), isTrue);
    });
  });

  group('AchievementsEngine — level milestones', () {
    test('totalXp 50 (level 1) unlocks no level achievements', () {
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty().copyWith(totalXp: 50),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.intersection({'level_3', 'level_5', 'level_10'}),
          isEmpty);
    });

    test('totalXp at level 5 threshold unlocks level_3 + level_5', () {
      // Progression.xpForLevel(5) == 1250
      final result = AchievementsEngine.evaluate(
        stats: const UserStats.empty().copyWith(totalXp: 1250),
        lessonProgress: LessonProgress.empty(),
        lessons: const [],
      );
      expect(result.contains('level_3'), isTrue);
      expect(result.contains('level_5'), isTrue);
      expect(result.contains('level_10'), isFalse);
    });
  });

  group('AchievementsEngine.newlyUnlocked', () {
    test('empty diff when nothing changed', () {
      final s = {'a', 'b'};
      expect(AchievementsEngine.newlyUnlocked(previous: s, current: s),
          isEmpty);
    });

    test('returns only newly added ids', () {
      final diff = AchievementsEngine.newlyUnlocked(
        previous: {'a'},
        current: {'a', 'b', 'c'},
      );
      expect(diff, {'b', 'c'});
    });

    test('returns empty when current is a subset', () {
      final diff = AchievementsEngine.newlyUnlocked(
        previous: {'a', 'b'},
        current: {'a'},
      );
      expect(diff, isEmpty);
    });
  });

  group('Achievement catalog integrity', () {
    test('every catalog id is unique', () {
      final ids = kAchievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'duplicate id in kAchievements');
    });

    test('every catalog entry has non-empty title and description', () {
      for (final a in kAchievements) {
        expect(a.title.isNotEmpty, isTrue, reason: 'title for ${a.id}');
        expect(a.description.isNotEmpty, isTrue,
            reason: 'description for ${a.id}');
      }
    });
  });
}
