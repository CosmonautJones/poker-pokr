import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

UserStats _stats({
  int handsPlayed = 0,
  int handsWon = 0,
  int lessonsCompleted = 0,
  int bestStreakDays = 0,
  int totalXp = 0,
}) =>
    UserStats(
      streakDays: 0,
      lastPlayedDay: null,
      totalXp: totalXp,
      handsPlayed: handsPlayed,
      lessonsCompleted: lessonsCompleted,
      bestStreakDays: bestStreakDays,
      handsWon: handsWon,
    );

void main() {
  group('achievements_catalog', () {
    test('catalog has stable IDs for all enum entries', () {
      final ids = achievementsCatalog.map((a) => a.id).toSet();
      // Catalog must cover every declared enum value — drift between the
      // enum and the catalog would silently orphan unlocks.
      expect(ids, AchievementId.values.toSet());
    });

    test('thresholds are positive', () {
      for (final a in achievementsCatalog) {
        expect(a.threshold, greaterThan(0), reason: a.id.name);
      }
    });
  });

  group('currentlyEarned', () {
    test('empty stats earns nothing', () {
      expect(currentlyEarned(_stats()), isEmpty);
    });

    test('1 hand played unlocks firstDeal only (volume)', () {
      final earned = currentlyEarned(_stats(handsPlayed: 1));
      expect(earned, contains(AchievementId.firstDeal));
      expect(earned, isNot(contains(AchievementId.gettingComfortable)));
    });

    test('100 hands played unlocks all three volume tiers', () {
      final earned = currentlyEarned(_stats(handsPlayed: 120));
      expect(earned, containsAll([
        AchievementId.firstDeal,
        AchievementId.gettingComfortable,
        AchievementId.marathonPlayer,
      ]));
    });

    test('handsWon thresholds gate showdown achievements independently', () {
      // 100 hands played but 0 won — no showdown achievements.
      final earned = currentlyEarned(_stats(handsPlayed: 100));
      expect(earned, isNot(contains(AchievementId.firstPot)));
      expect(earned, isNot(contains(AchievementId.hotHand)));
    });

    test('1 win unlocks firstPot only', () {
      final earned =
          currentlyEarned(_stats(handsPlayed: 1, handsWon: 1));
      expect(earned, contains(AchievementId.firstPot));
      expect(earned, isNot(contains(AchievementId.hotHand)));
    });

    test('50 wins unlocks all three showdown tiers', () {
      final earned = currentlyEarned(
          _stats(handsPlayed: 60, handsWon: 50));
      expect(earned, containsAll([
        AchievementId.firstPot,
        AchievementId.hotHand,
        AchievementId.bigWinner,
      ]));
    });

    test('streak achievements use bestStreakDays, not current streak', () {
      // Best 7, current 0 (broken streak) — Week Warrior should still unlock.
      final earned = currentlyEarned(_stats(bestStreakDays: 7));
      expect(earned, contains(AchievementId.threeOnTheTrot));
      expect(earned, contains(AchievementId.weekWarrior));
      expect(earned, isNot(contains(AchievementId.lockedIn)));
    });

    test('15 lessons unlocks both eagerStudent and topOfTheClass', () {
      final earned = currentlyEarned(_stats(lessonsCompleted: 15));
      expect(earned, containsAll([
        AchievementId.eagerStudent,
        AchievementId.topOfTheClass,
      ]));
    });

    test('Sharp Eye unlocks at level 10 (xp = 50 * 100 = 5000)', () {
      // Just under: 4999 XP → level 9.
      final under = currentlyEarned(_stats(totalXp: 4999));
      expect(under, isNot(contains(AchievementId.sharpEye)));
      // At threshold: 5000 XP → level 10.
      final at = currentlyEarned(_stats(totalXp: 5000));
      expect(at, contains(AchievementId.sharpEye));
    });
  });

  group('Achievement.progress', () {
    test('returns capped 1.0 once threshold reached', () {
      final firstDeal = achievementsCatalog
          .firstWhere((a) => a.id == AchievementId.firstDeal);
      expect(firstDeal.progress(_stats(handsPlayed: 1)), 1.0);
      expect(firstDeal.progress(_stats(handsPlayed: 100)), 1.0);
    });

    test('returns fractional progress under threshold', () {
      final marathon = achievementsCatalog
          .firstWhere((a) => a.id == AchievementId.marathonPlayer);
      expect(marathon.progress(_stats(handsPlayed: 50)), 0.5);
      expect(marathon.progress(_stats(handsPlayed: 0)), 0.0);
    });
  });
}
