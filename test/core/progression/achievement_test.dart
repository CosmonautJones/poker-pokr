import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  group('AchievementCatalog', () {
    test('all ids are unique', () {
      final ids = AchievementCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'duplicate achievement ids would orphan user unlocks');
    });

    test('all targets are positive', () {
      for (final a in AchievementCatalog.all) {
        expect(a.target, greaterThan(0), reason: a.id);
      }
    });

    test('byId returns null for unknown ids', () {
      expect(AchievementCatalog.byId('no_such_id'), isNull);
    });

    test('byId resolves every catalog id', () {
      for (final a in AchievementCatalog.all) {
        expect(AchievementCatalog.byId(a.id)?.id, a.id);
      }
    });

    test('progress fraction clamps to [0,1]', () {
      final a = AchievementCatalog.all
          .firstWhere((a) => a.id == 'grind_hands_10');
      expect(
        a.progressFraction(const UserStats.empty().copyWith(handsPlayed: 0)),
        0.0,
      );
      expect(
        a.progressFraction(const UserStats.empty().copyWith(handsPlayed: 5)),
        closeTo(0.5, 1e-9),
      );
      expect(
        a.progressFraction(const UserStats.empty().copyWith(handsPlayed: 10)),
        1.0,
      );
      // Over target is clamped, not truncated mid-calculation.
      expect(
        a.progressFraction(
          const UserStats.empty().copyWith(handsPlayed: 999),
        ),
        1.0,
      );
    });
  });

  group('AchievementEvaluator.newlyUnlocked', () {
    test('returns empty when nothing crossed a threshold', () {
      const prev = UserStats.empty();
      final next = prev.copyWith(handsPlayed: 0);
      expect(
        AchievementEvaluator.newlyUnlocked(prev: prev, next: next),
        isEmpty,
      );
    });

    test('first-hand transition unlocks welcome trophy', () {
      const prev = UserStats.empty();
      final next = prev.copyWith(handsPlayed: 1);
      final ids = AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      expect(ids, contains('grind_first_hand'));
    });

    test('multiple thresholds in one event all unlock', () {
      // Jump from 0 → 10 hands in one event: both first + 10th trophy.
      const prev = UserStats.empty();
      final next = prev.copyWith(handsPlayed: 10);
      final ids = AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      expect(ids, containsAll(['grind_first_hand', 'grind_hands_10']));
    });

    test('already-unlocked ids are never re-emitted', () {
      final prev = const UserStats.empty().copyWith(
        handsPlayed: 50,
        unlockedAchievements: {
          'grind_first_hand': _t(1),
          'grind_hands_10': _t(2),
        },
      );
      // Crosses grind_hands_50 only; the earlier two must NOT re-emit.
      final next = prev.copyWith(handsPlayed: 50);
      final ids = AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      expect(ids, contains('grind_hands_50'));
      expect(ids, isNot(contains('grind_first_hand')));
      expect(ids, isNot(contains('grind_hands_10')));
    });

    test('idempotent: calling twice with same next emits same list', () {
      const prev = UserStats.empty();
      final next = prev.copyWith(handsPlayed: 50);
      final first = AchievementEvaluator.newlyUnlocked(
        prev: prev,
        next: next,
      );
      final second = AchievementEvaluator.newlyUnlocked(
        prev: prev,
        next: next,
      );
      expect(second, equals(first));
    });

    test('ids come back in catalog order', () {
      const prev = UserStats.empty();
      final next = prev.copyWith(handsPlayed: 50, lessonsCompleted: 5);
      final ids =
          AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      final grindFirst = ids.indexOf('grind_first_hand');
      final grindTen = ids.indexOf('grind_hands_10');
      final grindFifty = ids.indexOf('grind_hands_50');
      expect(grindFirst, lessThan(grindTen));
      expect(grindTen, lessThan(grindFifty));
    });

    test('mastery level trophies unlock via totalXp', () {
      final prev = const UserStats.empty();
      // Level 5 = 50*5*5 = 1250 XP.
      final next = prev.copyWith(totalXp: 1250);
      final ids = AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      expect(ids, contains('mastery_level_5'));
      expect(ids, isNot(contains('mastery_level_10')));
    });

    test('streak trophies read bestStreakDays, not current', () {
      // Current streak broken but best preserved.
      final prev = const UserStats.empty();
      final next = prev.copyWith(streakDays: 1, bestStreakDays: 7);
      final ids = AchievementEvaluator.newlyUnlocked(prev: prev, next: next);
      expect(ids, contains('streak_days_3'));
      expect(ids, contains('streak_days_7'));
    });
  });

  group('AchievementEvaluator.satisfiedIds', () {
    test('empty stats satisfies nothing', () {
      expect(AchievementEvaluator.satisfiedIds(const UserStats.empty()),
          isEmpty);
    });

    test('backfill reports every currently-earned trophy', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 55,
        lessonsCompleted: 5,
        bestStreakDays: 3,
        totalXp: 1250,
      );
      final ids = AchievementEvaluator.satisfiedIds(stats);
      expect(ids, contains('grind_first_hand'));
      expect(ids, contains('grind_hands_10'));
      expect(ids, contains('grind_hands_50'));
      expect(ids, contains('study_first_lesson'));
      expect(ids, contains('study_lessons_5'));
      expect(ids, contains('streak_days_3'));
      expect(ids, contains('mastery_level_5'));
      // Unreached ones stay locked.
      expect(ids, isNot(contains('grind_hands_200')));
      expect(ids, isNot(contains('streak_days_30')));
      expect(ids, isNot(contains('mastery_level_10')));
    });
  });
}

DateTime _t(int day) => DateTime.utc(2026, 4, day);
