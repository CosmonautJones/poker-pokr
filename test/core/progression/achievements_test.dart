import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';

UserStats _statsWith({
  int streakDays = 0,
  int bestStreakDays = 0,
  int handsPlayed = 0,
  int lessonsCompleted = 0,
  int totalXp = 0,
}) {
  return UserStats(
    streakDays: streakDays,
    lastPlayedDay: null,
    totalXp: totalXp,
    handsPlayed: handsPlayed,
    lessonsCompleted: lessonsCompleted,
    bestStreakDays: bestStreakDays,
  );
}

void main() {
  group('AchievementsCatalog', () {
    test('catalog has at least 14 entries', () {
      expect(AchievementsCatalog.all.length, greaterThanOrEqualTo(14));
    });

    test('all achievement ids are unique', () {
      final ids = AchievementsCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('required ids are present', () {
      const required = {
        'first_hand',
        'first_lesson',
        'streak_3',
        'streak_7',
        'streak_30',
        'hands_10',
        'hands_50',
        'hands_250',
        'lessons_5',
        'lessons_all',
        'level_5',
        'level_10',
        'first_session',
        'bankroll_positive',
      };
      final got = AchievementsCatalog.all.map((a) => a.id).toSet();
      for (final id in required) {
        expect(got.contains(id), isTrue, reason: 'missing $id');
      }
    });

    test('first_hand fires when handsPlayed transitions 0 -> 1', () {
      final stats = _statsWith(handsPlayed: 1);
      final unlocks = AchievementsCatalog.evaluate(
        stats: stats,
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
      );
      expect(unlocks.map((a) => a.id), contains('first_hand'));
    });

    test('streak_7 fires at exactly 7 days', () {
      final unlocks = AchievementsCatalog.evaluate(
        stats: _statsWith(streakDays: 7, bestStreakDays: 7),
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
      );
      final ids = unlocks.map((a) => a.id).toSet();
      expect(ids.contains('streak_3'), isTrue);
      expect(ids.contains('streak_7'), isTrue);
      expect(ids.contains('streak_30'), isFalse);
    });

    test('lessons_all requires matching catalog length', () {
      final total = lessonsCatalog.length;
      final shy = AchievementsCatalog.evaluate(
        stats: _statsWith(lessonsCompleted: total - 1),
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
      );
      expect(shy.map((a) => a.id).contains('lessons_all'), isFalse);

      final hit = AchievementsCatalog.evaluate(
        stats: _statsWith(lessonsCompleted: total),
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
      );
      expect(hit.map((a) => a.id).contains('lessons_all'), isTrue);
    });

    test('evaluate is idempotent — unlocks fire only once', () {
      final stats = _statsWith(handsPlayed: 1);
      final first = AchievementsCatalog.evaluate(
        stats: stats,
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
      );
      expect(first.map((a) => a.id).contains('first_hand'), isTrue);

      final current = AchievementProgress(
        unlockedAt: {for (final a in first) a.id: DateTime(2026, 4, 23)},
      );
      final second = AchievementsCatalog.evaluate(
        stats: stats,
        current: current,
        now: DateTime(2026, 4, 24),
      );
      expect(second.map((a) => a.id).contains('first_hand'), isFalse);
    });

    test('session profit unlocks first_session and bankroll_positive', () {
      final unlocks = AchievementsCatalog.evaluate(
        stats: _statsWith(),
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
        latestSessionProfitCents: 5000,
      );
      final ids = unlocks.map((a) => a.id).toSet();
      expect(ids.contains('first_session'), isTrue);
      expect(ids.contains('bankroll_positive'), isTrue);
    });

    test('losing session unlocks first_session but not bankroll_positive', () {
      final unlocks = AchievementsCatalog.evaluate(
        stats: _statsWith(),
        current: const AchievementProgress.empty(),
        now: DateTime(2026, 4, 23),
        latestSessionProfitCents: -1500,
      );
      final ids = unlocks.map((a) => a.id).toSet();
      expect(ids.contains('first_session'), isTrue);
      expect(ids.contains('bankroll_positive'), isFalse);
    });
  });

  group('AchievementProgress', () {
    test('JSON roundtrip preserves entries', () {
      final prog = AchievementProgress(unlockedAt: {
        'first_hand': DateTime.utc(2026, 4, 23, 12, 0),
        'streak_3': DateTime.utc(2026, 4, 24, 8, 30),
      });
      final decoded = AchievementProgress.tryDecode(prog.encode());
      expect(decoded, isNotNull);
      expect(decoded!.unlockedAt.length, 2);
      expect(decoded.unlockedAt['first_hand'],
          DateTime.utc(2026, 4, 23, 12, 0));
      expect(decoded.unlockedAt['streak_3'],
          DateTime.utc(2026, 4, 24, 8, 30));
    });

    test('tryDecode returns null for invalid input', () {
      expect(AchievementProgress.tryDecode(null), isNull);
      expect(AchievementProgress.tryDecode(''), isNull);
      expect(AchievementProgress.tryDecode('not-json'), isNull);
    });

    test('unlockedCount and isUnlocked', () {
      final prog = AchievementProgress(unlockedAt: {
        'first_hand': DateTime(2026, 4, 23),
        'streak_3': DateTime(2026, 4, 24),
      });
      expect(prog.unlockedCount, 2);
      expect(prog.isUnlocked('first_hand'), isTrue);
      expect(prog.isUnlocked('streak_30'), isFalse);
    });
  });
}
