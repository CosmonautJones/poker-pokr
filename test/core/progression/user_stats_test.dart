import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('Progression.xpForLevel / levelForXp', () {
    test('level 0 is 0 XP', () {
      expect(Progression.xpForLevel(0), 0);
      expect(Progression.levelForXp(0), 0);
    });

    test('quadratic curve: 50/200/450/800', () {
      expect(Progression.xpForLevel(1), 50);
      expect(Progression.xpForLevel(2), 200);
      expect(Progression.xpForLevel(3), 450);
      expect(Progression.xpForLevel(4), 800);
      expect(Progression.xpForLevel(5), 1250);
    });

    test('levelForXp rounds down to next threshold', () {
      expect(Progression.levelForXp(49), 0);
      expect(Progression.levelForXp(50), 1);
      expect(Progression.levelForXp(199), 1);
      expect(Progression.levelForXp(200), 2);
      expect(Progression.levelForXp(1249), 4);
      expect(Progression.levelForXp(1250), 5);
    });

    test('levelForXp is inverse of xpForLevel at boundary', () {
      for (int lvl = 0; lvl <= 10; lvl++) {
        expect(Progression.levelForXp(Progression.xpForLevel(lvl)), lvl);
      }
    });
  });

  group('Progression.applyActivity', () {
    final jan1 = DateTime(2026, 1, 1, 10, 0);
    final jan1Night = DateTime(2026, 1, 1, 23, 30);
    final jan2 = DateTime(2026, 1, 2, 9, 0);
    final jan3 = DateTime(2026, 1, 3, 9, 0);
    final jan5 = DateTime(2026, 1, 5, 9, 0);

    test('first ever play: streak=1, bonus granted', () {
      const prev = UserStats.empty();
      final r = Progression.applyActivity(prev, jan1);
      expect(r.newStreakDays, 1);
      expect(r.newLastPlayedDay, Progression.dayKey(jan1));
      expect(r.dailyBonusXp, Progression.xpDailyBonus);
    });

    test('same calendar day: streak unchanged, no bonus', () {
      final prev = const UserStats.empty()
          .copyWith(streakDays: 3, lastPlayedDay: jan1);
      final r = Progression.applyActivity(prev, jan1Night);
      expect(r.newStreakDays, 3);
      expect(r.dailyBonusXp, 0);
      expect(r.newLastPlayedDay, Progression.dayKey(jan1));
    });

    test('next day: streak +=1, bonus granted', () {
      final prev = const UserStats.empty()
          .copyWith(streakDays: 3, lastPlayedDay: jan1);
      final r = Progression.applyActivity(prev, jan2);
      expect(r.newStreakDays, 4);
      expect(r.dailyBonusXp, Progression.xpDailyBonus);
      expect(r.newLastPlayedDay, Progression.dayKey(jan2));
    });

    test('gap of 2 days: streak resets to 1', () {
      final prev = const UserStats.empty()
          .copyWith(streakDays: 5, lastPlayedDay: jan1);
      final r = Progression.applyActivity(prev, jan3);
      expect(r.newStreakDays, 1);
      expect(r.dailyBonusXp, Progression.xpDailyBonus);
    });

    test('long gap: streak resets to 1', () {
      final prev = const UserStats.empty()
          .copyWith(streakDays: 12, lastPlayedDay: jan1);
      final r = Progression.applyActivity(prev, jan5);
      expect(r.newStreakDays, 1);
      expect(r.dailyBonusXp, Progression.xpDailyBonus);
    });

    test('dayKey strips time-of-day', () {
      expect(
        Progression.dayKey(DateTime(2026, 3, 5, 17, 42, 13)),
        DateTime(2026, 3, 5),
      );
    });
  });

  group('UserStats serialization', () {
    test('encode / decode roundtrip preserves fields', () {
      final stats = UserStats(
        streakDays: 4,
        lastPlayedDay: DateTime(2026, 4, 19),
        totalXp: 325,
        handsPlayed: 18,
        lessonsCompleted: 3,
        bestStreakDays: 7,
        lifetimeWins: 9,
        unlockedAchievements: const ['first_hand', 'streak_3'],
        dailyChallengeLastCompletedDay: DateTime(2026, 4, 19),
        dailyChallengesCompleted: 2,
      );
      final decoded = UserStats.tryDecode(stats.encode())!;
      expect(decoded.streakDays, 4);
      expect(decoded.lastPlayedDay, DateTime(2026, 4, 19));
      expect(decoded.totalXp, 325);
      expect(decoded.handsPlayed, 18);
      expect(decoded.lessonsCompleted, 3);
      expect(decoded.bestStreakDays, 7);
      expect(decoded.lifetimeWins, 9);
      expect(decoded.unlockedAchievements, ['first_hand', 'streak_3']);
      expect(decoded.dailyChallengeLastCompletedDay, DateTime(2026, 4, 19));
      expect(decoded.dailyChallengesCompleted, 2);
    });

    test('decode tolerates legacy payloads missing new fields', () {
      // Mirror what an older v1 install would have written before the
      // achievements/daily-challenge fields existed.
      const legacy = '{'
          '"streakDays":2,'
          '"lastPlayedDay":"2026-04-19T00:00:00.000",'
          '"totalXp":120,'
          '"handsPlayed":4,'
          '"lessonsCompleted":1,'
          '"bestStreakDays":3'
          '}';
      final decoded = UserStats.tryDecode(legacy)!;
      expect(decoded.streakDays, 2);
      expect(decoded.lifetimeWins, 0);
      expect(decoded.unlockedAchievements, isEmpty);
      expect(decoded.dailyChallengeLastCompletedDay, isNull);
      expect(decoded.dailyChallengesCompleted, 0);
    });

    test('dailyChallengeDoneOn matches local calendar day', () {
      final stats = const UserStats.empty().copyWith(
        dailyChallengeLastCompletedDay: DateTime(2026, 5, 3, 12, 0),
      );
      expect(stats.dailyChallengeDoneOn(DateTime(2026, 5, 3, 23)), isTrue);
      expect(stats.dailyChallengeDoneOn(DateTime(2026, 5, 4, 0, 1)), isFalse);
    });

    test('tryDecode returns null for garbage and empty', () {
      expect(UserStats.tryDecode(null), isNull);
      expect(UserStats.tryDecode(''), isNull);
      expect(UserStats.tryDecode('not json'), isNull);
    });

    test('tryDecode is tolerant of missing fields', () {
      final decoded = UserStats.tryDecode('{}');
      expect(decoded, isNotNull);
      expect(decoded!.streakDays, 0);
      expect(decoded.totalXp, 0);
      expect(decoded.lastPlayedDay, isNull);
    });
  });

  group('UserStats derived getters', () {
    test('level/xpIntoLevel/levelProgress at level boundary', () {
      final stats = const UserStats.empty().copyWith(totalXp: 50);
      expect(stats.level, 1);
      expect(stats.xpIntoLevel, 0);
      expect(stats.levelProgress, 0.0);
    });

    test('levelProgress is halfway between levels', () {
      // L1 = 50, L2 = 200 → halfway = 125
      final stats = const UserStats.empty().copyWith(totalXp: 125);
      expect(stats.level, 1);
      expect(stats.xpIntoLevel, 75);
      expect(stats.xpNeededForNextLevel, 150);
      expect(stats.levelProgress, closeTo(0.5, 1e-6));
    });
  });
}
