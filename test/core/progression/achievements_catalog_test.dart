import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('achievementCatalog integrity', () {
    test('ids are unique', () {
      final ids = achievementCatalog.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'duplicate achievement id in catalog');
    });

    test('catalog covers all four rarity tiers', () {
      final tiers = achievementCatalog.map((a) => a.rarity).toSet();
      expect(tiers, containsAll(AchievementRarity.values));
    });

    test('empty stats unlock nothing', () {
      for (final a in achievementCatalog) {
        expect(a.condition(const UserStats.empty()), isFalse,
            reason: '${a.id} should not unlock on a fresh install');
      }
    });
  });

  group('achievementById', () {
    test('returns definition for known id', () {
      final a = achievementById('first_hand');
      expect(a, isNotNull);
      expect(a!.rarity, AchievementRarity.common);
    });

    test('returns null for unknown id', () {
      expect(achievementById('not_a_real_id'), isNull);
    });
  });

  group('detectNewlyUnlocked', () {
    test('first hand unlocks first_hand only', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 20,
        handsPlayed: 1,
        lessonsCompleted: 0,
        bestStreakDays: 1,
      );
      final unlocked = detectNewlyUnlocked(stats, const {});
      expect(unlocked, contains('first_hand'));
      expect(unlocked, isNot(contains('hands_5')));
      expect(unlocked, isNot(contains('first_lesson')));
    });

    test('skips ids already in alreadyUnlocked', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 20,
        handsPlayed: 1,
        lessonsCompleted: 0,
        bestStreakDays: 1,
      );
      final unlocked = detectNewlyUnlocked(stats, const {'first_hand'});
      expect(unlocked, isEmpty);
    });

    test('level-based achievements evaluate against derived level', () {
      // Level 5 threshold: xpForLevel(5) = 50 * 25 = 1250.
      const stats = UserStats(
        streakDays: 0,
        lastPlayedDay: null,
        totalXp: 1250,
        handsPlayed: 0,
        lessonsCompleted: 0,
        bestStreakDays: 0,
      );
      final unlocked = detectNewlyUnlocked(stats, const {});
      expect(unlocked, contains('level_5'));
      expect(unlocked, isNot(contains('level_10')));
    });

    test('crossing a threshold unlocks only the newly-satisfied tier', () {
      const before = UserStats(
        streakDays: 0,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 4,
        lessonsCompleted: 0,
        bestStreakDays: 0,
        unlockedAchievementIds: {'first_hand'},
      );
      final afterUnlocked =
          detectNewlyUnlocked(before, before.unlockedAchievementIds);
      expect(afterUnlocked, isEmpty);

      const crossed = UserStats(
        streakDays: 0,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 5,
        lessonsCompleted: 0,
        bestStreakDays: 0,
        unlockedAchievementIds: {'first_hand'},
      );
      final newIds =
          detectNewlyUnlocked(crossed, crossed.unlockedAchievementIds);
      expect(newIds, {'hands_5'});
    });

    test('all_lessons matches kTotalLessonScenarios threshold', () {
      final stats = const UserStats.empty()
          .copyWith(lessonsCompleted: kTotalLessonScenarios);
      final unlocked = detectNewlyUnlocked(stats, const {});
      expect(unlocked, contains('all_lessons'));
    });
  });
}
