import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('AchievementsCatalog', () {
    test('all ids are unique', () {
      final ids = AchievementsCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('byId returns matching entry or null', () {
      expect(AchievementsCatalog.byId('first_hand'), isNotNull);
      expect(AchievementsCatalog.byId('first_hand')!.title, 'First Hand');
      expect(AchievementsCatalog.byId('does_not_exist'), isNull);
    });

    test('every entry has a stable, non-empty id and title', () {
      for (final a in AchievementsCatalog.all) {
        expect(a.id, isNotEmpty);
        expect(a.title, isNotEmpty);
        expect(a.description, isNotEmpty);
      }
    });
  });

  group('Achievement predicates — volume', () {
    final firstHand = AchievementsCatalog.byId('first_hand')!;
    final apprentice = AchievementsCatalog.byId('apprentice')!;
    final sharp = AchievementsCatalog.byId('sharp')!;

    test('first_hand fires at 1 hand played', () {
      expect(firstHand.predicate(const UserStats.empty()), isFalse);
      final played = const UserStats.empty().copyWith(handsPlayed: 1);
      expect(firstHand.predicate(played), isTrue);
    });

    test('apprentice fires at exactly 10 hands', () {
      expect(
        apprentice.predicate(const UserStats.empty().copyWith(handsPlayed: 9)),
        isFalse,
      );
      expect(
        apprentice.predicate(
          const UserStats.empty().copyWith(handsPlayed: 10),
        ),
        isTrue,
      );
    });

    test('sharp requires 50+ hands', () {
      expect(
        sharp.predicate(const UserStats.empty().copyWith(handsPlayed: 49)),
        isFalse,
      );
      expect(
        sharp.predicate(const UserStats.empty().copyWith(handsPlayed: 50)),
        isTrue,
      );
    });
  });

  group('Achievement predicates — winning', () {
    final firstWin = AchievementsCatalog.byId('first_win')!;
    final crusher = AchievementsCatalog.byId('crusher')!;

    test('first_win fires at 1 win', () {
      expect(firstWin.predicate(const UserStats.empty()), isFalse);
      expect(
        firstWin.predicate(const UserStats.empty().copyWith(handsWon: 1)),
        isTrue,
      );
    });

    test('crusher requires 50 wins', () {
      expect(
        crusher.predicate(const UserStats.empty().copyWith(handsWon: 49)),
        isFalse,
      );
      expect(
        crusher.predicate(const UserStats.empty().copyWith(handsWon: 50)),
        isTrue,
      );
    });
  });

  group('Achievement predicates — streak', () {
    final hotStreak = AchievementsCatalog.byId('hot_streak')!;
    final weekWarrior = AchievementsCatalog.byId('week_warrior')!;
    final unbreakable = AchievementsCatalog.byId('unbreakable')!;

    test('hot_streak fires at 3-day best streak', () {
      expect(
        hotStreak
            .predicate(const UserStats.empty().copyWith(bestStreakDays: 2)),
        isFalse,
      );
      expect(
        hotStreak
            .predicate(const UserStats.empty().copyWith(bestStreakDays: 3)),
        isTrue,
      );
    });

    test('week_warrior fires at 7-day best streak', () {
      expect(
        weekWarrior
            .predicate(const UserStats.empty().copyWith(bestStreakDays: 7)),
        isTrue,
      );
    });

    test('unbreakable requires 30-day streak', () {
      expect(
        unbreakable
            .predicate(const UserStats.empty().copyWith(bestStreakDays: 29)),
        isFalse,
      );
      expect(
        unbreakable
            .predicate(const UserStats.empty().copyWith(bestStreakDays: 30)),
        isTrue,
      );
    });
  });

  group('Achievement predicates — mastery', () {
    final firstLesson = AchievementsCatalog.byId('first_lesson')!;
    final scholar = AchievementsCatalog.byId('scholar')!;
    final risingStar = AchievementsCatalog.byId('rising_star')!;
    final tableMaster = AchievementsCatalog.byId('table_master')!;

    test('first_lesson fires at 1 lesson', () {
      expect(firstLesson.predicate(const UserStats.empty()), isFalse);
      expect(
        firstLesson.predicate(
          const UserStats.empty().copyWith(lessonsCompleted: 1),
        ),
        isTrue,
      );
    });

    test('scholar requires 5 lessons', () {
      expect(
        scholar.predicate(
          const UserStats.empty().copyWith(lessonsCompleted: 4),
        ),
        isFalse,
      );
      expect(
        scholar.predicate(
          const UserStats.empty().copyWith(lessonsCompleted: 5),
        ),
        isTrue,
      );
    });

    test('rising_star fires at level 5 (1250 XP)', () {
      expect(
        risingStar
            .predicate(const UserStats.empty().copyWith(totalXp: 1249)),
        isFalse,
      );
      expect(
        risingStar
            .predicate(const UserStats.empty().copyWith(totalXp: 1250)),
        isTrue,
      );
    });

    test('table_master fires at level 10 (5000 XP)', () {
      expect(
        tableMaster
            .predicate(const UserStats.empty().copyWith(totalXp: 4999)),
        isFalse,
      );
      expect(
        tableMaster
            .predicate(const UserStats.empty().copyWith(totalXp: 5000)),
        isTrue,
      );
    });
  });

  group('Achievement predicates — big hand', () {
    final flushAch = AchievementsCatalog.byId('big_hand_flush')!;
    final fhAch = AchievementsCatalog.byId('big_hand_full_house')!;
    final quadsAch = AchievementsCatalog.byId('big_hand_quads')!;
    final sfAch = AchievementsCatalog.byId('big_hand_straight_flush')!;

    test('flush requires bestHandRankIndex >= 5', () {
      expect(
        flushAch.predicate(
            const UserStats.empty().copyWith(bestHandRankIndex: 4)),
        isFalse,
      );
      expect(
        flushAch.predicate(
            const UserStats.empty().copyWith(bestHandRankIndex: 5)),
        isTrue,
      );
    });

    test('higher hand classes also satisfy lower ones', () {
      // Hitting a straight flush (8) implies all big-hand achievements.
      final s = const UserStats.empty().copyWith(bestHandRankIndex: 8);
      expect(flushAch.predicate(s), isTrue);
      expect(fhAch.predicate(s), isTrue);
      expect(quadsAch.predicate(s), isTrue);
      expect(sfAch.predicate(s), isTrue);
    });

    test('default (-1) satisfies no big-hand achievements', () {
      const s = UserStats.empty();
      expect(flushAch.predicate(s), isFalse);
      expect(fhAch.predicate(s), isFalse);
      expect(quadsAch.predicate(s), isFalse);
      expect(sfAch.predicate(s), isFalse);
    });
  });
}
