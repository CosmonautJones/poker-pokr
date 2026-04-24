import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('achievementsCatalog', () {
    test('all ids are unique', () {
      final ids = achievementsCatalog.map((a) => a.id).toSet();
      expect(ids.length, achievementsCatalog.length);
    });

    test('no achievement is unlocked on a brand-new install', () {
      const stats = UserStats.empty();
      for (final a in achievementsCatalog) {
        expect(
          a.isUnlocked(stats),
          isFalse,
          reason: '${a.id} must not unlock on empty stats',
        );
      }
    });

    test('first_hand unlocks on a single hand played', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 1);
      final byId = {for (final a in achievementsCatalog) a.id: a};
      expect(byId['first_hand']!.isUnlocked(stats), isTrue);
    });

    test('first_win requires a win even if hands are played', () {
      final lost = const UserStats.empty().copyWith(handsPlayed: 5);
      final won = lost.copyWith(handsWon: 1);
      final byId = {for (final a in achievementsCatalog) a.id: a};
      expect(byId['first_win']!.isUnlocked(lost), isFalse);
      expect(byId['first_win']!.isUnlocked(won), isTrue);
    });

    test('streak achievements key off bestStreakDays, not current streak', () {
      // Player had a 7-day streak, currently broken — legacy best still
      // qualifies them for streak_three and streak_seven.
      final stats = const UserStats.empty().copyWith(
        streakDays: 1,
        bestStreakDays: 7,
      );
      final byId = {for (final a in achievementsCatalog) a.id: a};
      expect(byId['streak_three']!.isUnlocked(stats), isTrue);
      expect(byId['streak_seven']!.isUnlocked(stats), isTrue);
      expect(byId['streak_thirty']!.isUnlocked(stats), isFalse);
    });

    test('level_five unlocks at 1250 total XP (level 5 threshold)', () {
      final justBelow = const UserStats.empty().copyWith(totalXp: 1249);
      final atLevel = const UserStats.empty().copyWith(totalXp: 1250);
      final byId = {for (final a in achievementsCatalog) a.id: a};
      expect(byId['level_five']!.isUnlocked(justBelow), isFalse);
      expect(byId['level_five']!.isUnlocked(atLevel), isTrue);
    });
  });

  group('newlyUnlockedAchievements', () {
    test('returns empty when no stats changed meaningfully', () {
      const before = UserStats.empty();
      const after = UserStats.empty();
      final fresh = newlyUnlockedAchievements(
        before: before,
        after: after,
        catalog: achievementsCatalog,
      );
      expect(fresh, isEmpty);
    });

    test('returns ids that flipped from locked to unlocked', () {
      const before = UserStats.empty();
      final after = before.copyWith(handsPlayed: 1, handsWon: 1);
      final fresh = newlyUnlockedAchievements(
        before: before,
        after: after,
        catalog: achievementsCatalog,
      );
      expect(fresh, contains('first_hand'));
      expect(fresh, contains('first_win'));
      expect(fresh, isNot(contains('hundred_hands')));
    });

    test('never re-emits an already-unlocked achievement', () {
      final before = const UserStats.empty().copyWith(
        handsPlayed: 1,
        unlockedAchievementIds: const {'first_hand'},
      );
      final after = before.copyWith(handsPlayed: 2);
      final fresh = newlyUnlockedAchievements(
        before: before,
        after: after,
        catalog: achievementsCatalog,
      );
      expect(fresh, isNot(contains('first_hand')));
    });

    test('multiple unlocks from a single stat jump', () {
      const before = UserStats.empty();
      // Big jump: 10 hands played, 1 lesson, level 5.
      final after = before.copyWith(
        handsPlayed: 10,
        handsWon: 2,
        lessonsCompleted: 1,
        totalXp: 1250,
      );
      final fresh = newlyUnlockedAchievements(
        before: before,
        after: after,
        catalog: achievementsCatalog,
      );
      expect(
        fresh,
        containsAll(<String>[
          'first_hand',
          'first_win',
          'ten_hands',
          'first_lesson',
          'level_five',
        ]),
      );
      // 100-hand not unlocked yet.
      expect(fresh, isNot(contains('hundred_hands')));
    });
  });
}
