import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('achievementCatalog', () {
    test('catalog has unique ids', () {
      final ids = achievementCatalog.map((a) => a.id).toList();
      expect(ids.length, ids.toSet().length,
          reason: 'duplicate ids would corrupt unlock diffing');
    });

    test('catalog covers at least 12 achievements', () {
      // Acceptance criterion: ≥12 achievements available for the grid.
      expect(achievementCatalog.length, greaterThanOrEqualTo(12));
    });

    test('every achievement has non-empty title and description', () {
      for (final a in achievementCatalog) {
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
        expect(a.iconKey, isNotEmpty);
      }
    });

    test('findAchievementById returns null for unknown id', () {
      expect(findAchievementById('this_does_not_exist'), isNull);
    });
  });

  group('evaluateUnlockedIds', () {
    test('empty stats unlocks nothing', () {
      expect(evaluateUnlockedIds(const UserStats.empty()), isEmpty);
    });

    test('first hand unlocks first_hand', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 1);
      expect(evaluateUnlockedIds(stats), contains('first_hand'));
    });

    test('first lesson unlocks first_lesson', () {
      final stats = const UserStats.empty().copyWith(lessonsCompleted: 1);
      expect(evaluateUnlockedIds(stats), contains('first_lesson'));
    });

    test('first showdown win unlocks first_win', () {
      final stats = const UserStats.empty()
          .copyWith(handsPlayed: 1, lifetimeWins: 1);
      final ids = evaluateUnlockedIds(stats);
      expect(ids, contains('first_win'));
    });

    test('hand volume tiers cascade', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 50);
      final ids = evaluateUnlockedIds(stats);
      expect(ids, containsAll(<String>['first_hand', 'hands_10', 'hands_50']));
      expect(ids, isNot(contains('hands_250')));
    });

    test('streak tiers gate on bestStreakDays not current', () {
      final stats = const UserStats.empty().copyWith(
        streakDays: 1,
        bestStreakDays: 7,
      );
      expect(evaluateUnlockedIds(stats), containsAll(<String>[
        'streak_3',
        'streak_7',
      ]));
    });

    test('level milestones derive from XP', () {
      // Level 5 requires 1250 XP per the Progression curve.
      final stats = const UserStats.empty().copyWith(totalXp: 1250);
      expect(evaluateUnlockedIds(stats), contains('level_5'));
    });

    test('daily_5 only unlocks at 5 daily completions', () {
      final s4 = const UserStats.empty().copyWith(dailyChallengesCompleted: 4);
      expect(evaluateUnlockedIds(s4), isNot(contains('daily_5')));
      final s5 = const UserStats.empty().copyWith(dailyChallengesCompleted: 5);
      expect(evaluateUnlockedIds(s5), contains('daily_5'));
    });
  });

  group('newlyUnlocked', () {
    test('empty prev returns full next', () {
      expect(
        newlyUnlocked(const <String>[], const ['a', 'b']),
        const ['a', 'b'],
      );
    });

    test('preserves catalog order in result', () {
      expect(
        newlyUnlocked(const ['b'], const ['a', 'b', 'c']),
        const ['a', 'c'],
      );
    });

    test('returns empty when nothing changed', () {
      expect(newlyUnlocked(const ['a', 'b'], const ['a', 'b']), isEmpty);
    });
  });
}
