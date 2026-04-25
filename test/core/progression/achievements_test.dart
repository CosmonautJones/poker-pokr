import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/scenario_mastery.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

void main() {
  // A small synthetic catalog used by every test.
  const evaluator = AchievementEvaluator(
    totalScenarios: 4,
    scenarioKeysByLesson: {
      'drawing_hands': ['drawing_hands/0', 'drawing_hands/1'],
      'hand_protection': ['hand_protection/0', 'hand_protection/1'],
    },
  );

  group('AchievementEvaluator.disabled', () {
    test('reports zero progress and unlocks nothing', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 100,
        handsWon: 100,
        bestStreakDays: 100,
        totalXp: 100000,
      );
      for (final id in AchievementId.values) {
        final p = AchievementEvaluator.disabled.progress(id, stats);
        expect(p.target, 0);
        expect(p.isUnlocked, isFalse);
      }
      expect(AchievementEvaluator.disabled.unlockedSet(stats), isEmpty);
    });
  });

  group('progress for individual criteria', () {
    test('firstHand unlocks at 1 hand', () {
      var stats = const UserStats.empty();
      expect(evaluator.progress(AchievementId.firstHand, stats).isUnlocked,
          isFalse);
      stats = stats.copyWith(handsPlayed: 1);
      expect(evaluator.progress(AchievementId.firstHand, stats).isUnlocked,
          isTrue);
    });

    test('marathon needs 50 hands', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 49);
      final p = evaluator.progress(AchievementId.marathon, stats);
      expect(p.current, 49);
      expect(p.target, 50);
      expect(p.isUnlocked, isFalse);
      final p2 =
          evaluator.progress(AchievementId.marathon, stats.copyWith(handsPlayed: 50));
      expect(p2.isUnlocked, isTrue);
    });

    test('champion needs 25 wins', () {
      final stats = const UserStats.empty().copyWith(handsWon: 24);
      expect(evaluator.progress(AchievementId.champion, stats).isUnlocked,
          isFalse);
      expect(
        evaluator
            .progress(AchievementId.champion, stats.copyWith(handsWon: 25))
            .isUnlocked,
        isTrue,
      );
    });

    test('streakWeek and streakMonth gate on bestStreakDays', () {
      final stats = const UserStats.empty().copyWith(bestStreakDays: 7);
      expect(
        evaluator.progress(AchievementId.streakWeek, stats).isUnlocked,
        isTrue,
      );
      expect(
        evaluator.progress(AchievementId.streakMonth, stats).isUnlocked,
        isFalse,
      );
      expect(
        evaluator
            .progress(AchievementId.streakMonth,
                stats.copyWith(bestStreakDays: 30))
            .isUnlocked,
        isTrue,
      );
    });

    test('level5 / level10 gate on derived level', () {
      // L5 = 1250 XP, L10 = 5000 XP.
      final stats = const UserStats.empty().copyWith(totalXp: 1250);
      expect(
        evaluator.progress(AchievementId.level5, stats).isUnlocked,
        isTrue,
      );
      expect(
        evaluator.progress(AchievementId.level10, stats).isUnlocked,
        isFalse,
      );
      expect(
        evaluator
            .progress(AchievementId.level10, stats.copyWith(totalXp: 5000))
            .isUnlocked,
        isTrue,
      );
    });

    test('perfectionist needs at least one 3-star scenario', () {
      var stats = const UserStats.empty();
      expect(
        evaluator.progress(AchievementId.perfectionist, stats).isUnlocked,
        isFalse,
      );
      stats = stats.copyWith(scenarioMastery: {
        'drawing_hands/0': const MasteryRecord(
          completions: 3,
          cleanCompletions: 3,
          bestStars: 3,
        ),
      });
      expect(
        evaluator.progress(AchievementId.perfectionist, stats).isUnlocked,
        isTrue,
      );
    });

    test('graduate needs every scenario in some lesson at 3 stars', () {
      // 3-star one of two scenarios in drawing_hands → not yet.
      var stats = const UserStats.empty().copyWith(scenarioMastery: {
        'drawing_hands/0': const MasteryRecord(
          completions: 3,
          cleanCompletions: 3,
          bestStars: 3,
        ),
      });
      expect(
        evaluator.progress(AchievementId.graduate, stats).isUnlocked,
        isFalse,
      );
      // Now 3-star both scenarios in drawing_hands.
      stats = stats.copyWith(scenarioMastery: {
        ...stats.scenarioMastery,
        'drawing_hands/1': const MasteryRecord(
          completions: 3,
          cleanCompletions: 3,
          bestStars: 3,
        ),
      });
      final p = evaluator.progress(AchievementId.graduate, stats);
      expect(p.current, 2);
      expect(p.target, 2);
      expect(p.isUnlocked, isTrue);
    });
  });

  group('newlyUnlocked', () {
    test('returns only achievements not yet in unlockedAchievementIds', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 1);
      final fresh = evaluator.newlyUnlocked(stats);
      expect(fresh, contains(AchievementId.firstHand));
    });

    test('does not re-fire already-unlocked ids', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 1,
        unlockedAchievementIds: {AchievementId.firstHand.key},
      );
      final fresh = evaluator.newlyUnlocked(stats);
      expect(fresh, isEmpty);
    });
  });

  group('UserStats persistence with new fields', () {
    test('roundtrip preserves mastery + unlocked', () {
      final stats = UserStats(
        streakDays: 2,
        lastPlayedDay: DateTime(2026, 4, 25),
        totalXp: 200,
        handsPlayed: 5,
        handsWon: 1,
        lessonsCompleted: 1,
        bestStreakDays: 4,
        scenarioMastery: {
          'drawing_hands/0': MasteryRecord(
            completions: 2,
            cleanCompletions: 1,
            bestStars: 2,
            lastPlayedDay: DateTime(2026, 4, 25),
          ),
        },
        unlockedAchievementIds: {
          AchievementId.firstHand.key,
          AchievementId.scholar.key,
        },
      );
      final back = UserStats.tryDecode(stats.encode())!;
      expect(back.handsWon, 1);
      expect(back.scenarioMastery.length, 1);
      expect(back.scenarioMastery['drawing_hands/0']!.bestStars, 2);
      expect(back.unlockedAchievementIds, contains('firstHand'));
      expect(back.unlockedAchievementIds, contains('scholar'));
    });

    test('legacy stored payload (pre-mastery) decodes safely', () {
      // Simulates a v1 payload that lacked the new fields.
      const legacy = '{"streakDays":2,"lastPlayedDay":"2026-04-19T00:00:00.000",'
          '"totalXp":120,"handsPlayed":4,"lessonsCompleted":1,"bestStreakDays":3}';
      final back = UserStats.tryDecode(legacy)!;
      expect(back.handsWon, 0);
      expect(back.scenarioMastery, isEmpty);
      expect(back.unlockedAchievementIds, isEmpty);
      expect(back.totalXp, 120);
    });
  });
}
