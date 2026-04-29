import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievement_catalog.dart';
import 'package:poker_trainer/core/progression/achievement_engine.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('AchievementCatalog', () {
    test('ships at least twelve achievements', () {
      expect(AchievementCatalog.all.length, greaterThanOrEqualTo(12));
    });

    test('all ids are unique', () {
      final ids = AchievementCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every category has at least one achievement', () {
      final cats = AchievementCatalog.all.map((a) => a.category).toSet();
      for (final c in AchievementCategory.values) {
        expect(cats, contains(c), reason: 'missing category $c');
      }
    });

    test('byId returns the matching achievement', () {
      expect(AchievementCatalog.byId('firstHand'), isNotNull);
      expect(AchievementCatalog.byId('does-not-exist'), isNull);
    });
  });

  group('AchievementEngine.evaluate', () {
    test('empty stats unlocks nothing', () {
      const stats = UserStats.empty();
      final result = AchievementEngine.evaluate(stats, <String>{});
      expect(result.unlocked, isEmpty);
      expect(result.justUnlocked, isEmpty);
    });

    test('first hand played unlocks only firstHand', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 1);
      final result = AchievementEngine.evaluate(stats, <String>{});
      expect(result.unlocked, contains('firstHand'));
      expect(result.justUnlocked.map((a) => a.id), ['firstHand']);
    });

    test('multiple thresholds unlock together', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 100,
        handsWon: 10,
        lessonsCompleted: 5,
        bestStreakDays: 7,
        totalXp: 1250, // also reaches level 5
      );
      final result = AchievementEngine.evaluate(stats, <String>{});
      final ids = result.unlocked;
      expect(ids, containsAll(<String>[
        'firstHand', 'tenHands', 'hundredHands',
        'firstWin', 'tenWins',
        'firstLesson', 'fiveLessons',
        'weekStreak',
        'levelFive',
        'xpThousand',
      ]));
      // fiftyWins, tenLessons, monthStreak, levelTen are not yet earned.
      expect(ids, isNot(contains('fiftyWins')));
      expect(ids, isNot(contains('tenLessons')));
      expect(ids, isNot(contains('monthStreak')));
      expect(ids, isNot(contains('levelTen')));
      // justUnlocked excludes pre-existing entries.
      expect(result.justUnlocked.length, ids.length);
    });

    test('justUnlocked excludes previously-unlocked ids', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 10);
      final r1 = AchievementEngine.evaluate(stats, <String>{});
      // Snapshot first run's unlocked set.
      final r2 = AchievementEngine.evaluate(stats, r1.unlocked);
      expect(r2.justUnlocked, isEmpty);
      expect(r2.unlocked, r1.unlocked);
    });

    test('idempotent: running twice with same stats yields no new unlocks',
        () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 1,
        handsWon: 1,
      );
      final r1 = AchievementEngine.evaluate(stats, <String>{});
      final r2 = AchievementEngine.evaluate(stats, r1.unlocked);
      expect(r2.justUnlocked, isEmpty);
    });

    test('does not demote previously-unlocked ids when stats regress', () {
      // Hypothetical: stored set claims firstHand even though stats are
      // empty (e.g. user reset progression but achievement persistence
      // is independent). The engine must not strip the existing badge.
      const stats = UserStats.empty();
      final result =
          AchievementEngine.evaluate(stats, <String>{'firstHand'});
      expect(result.unlocked, contains('firstHand'));
      expect(result.justUnlocked, isEmpty);
    });

    test('unlock order matches catalog order', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 1,
        handsWon: 1,
        lessonsCompleted: 1,
      );
      final r = AchievementEngine.evaluate(stats, <String>{});
      // firstHand precedes firstWin which precedes firstLesson per catalog.
      final ids = r.justUnlocked.map((a) => a.id).toList();
      expect(ids.indexOf('firstHand'), lessThan(ids.indexOf('firstWin')));
      expect(ids.indexOf('firstWin'), lessThan(ids.indexOf('firstLesson')));
    });
  });

  group('progressOf / progressFraction', () {
    test('returns 0 for empty stats on incremental achievement', () {
      final tenHands = AchievementCatalog.byId('tenHands')!;
      const stats = UserStats.empty();
      expect(AchievementEngine.progressOf(tenHands, stats), 0.0);
    });

    test('returns clamped 1.0 once threshold met', () {
      final firstHand = AchievementCatalog.byId('firstHand')!;
      final stats = const UserStats.empty().copyWith(handsPlayed: 50);
      expect(AchievementEngine.progressOf(firstHand, stats), 1.0);
    });

    test('reports halfway progress', () {
      final tenHands = AchievementCatalog.byId('tenHands')!;
      final stats = const UserStats.empty().copyWith(handsPlayed: 5);
      expect(AchievementEngine.progressOf(tenHands, stats), closeTo(0.5, 1e-9));
    });

    test('progressFor caps at the target value', () {
      final tenHands = AchievementCatalog.byId('tenHands')!;
      final stats = const UserStats.empty().copyWith(handsPlayed: 999);
      expect(tenHands.progressFor(stats), tenHands.targetValue);
    });

    test('isUnlockedBy mirrors threshold check', () {
      final fiftyWins = AchievementCatalog.byId('fiftyWins')!;
      final under = const UserStats.empty().copyWith(handsWon: 49);
      final at = const UserStats.empty().copyWith(handsWon: 50);
      expect(fiftyWins.isUnlockedBy(under), isFalse);
      expect(fiftyWins.isUnlockedBy(at), isTrue);
    });
  });
}
