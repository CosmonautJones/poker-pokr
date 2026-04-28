import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';

UserStats _stats({
  int hands = 0,
  int lessons = 0,
  int streak = 0,
  int bestStreak = 0,
}) {
  return UserStats(
    streakDays: streak,
    lastPlayedDay: streak > 0 ? DateTime(2026, 4, 28) : null,
    totalXp: 0,
    handsPlayed: hands,
    lessonsCompleted: lessons,
    bestStreakDays: bestStreak == 0 ? streak : bestStreak,
  );
}

void main() {
  group('Achievements catalog', () {
    test('exposes 10 definitions with unique ids and stable ordering', () {
      expect(Achievements.all, hasLength(10));
      final ids = Achievements.all.map((d) => d.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'ids must be unique');
      expect(ids, contains('first_hand'));
      expect(ids, contains('streak_7'));
    });

    test('byId resolves known ids and returns null for unknown', () {
      expect(Achievements.byId('first_hand'), isNotNull);
      expect(Achievements.byId('does_not_exist'), isNull);
    });

    test('defaults() returns all locked, one entry per definition', () {
      final list = Achievements.defaults();
      expect(list, hasLength(Achievements.all.length));
      expect(list.every((a) => !a.isUnlocked), isTrue);
    });
  });

  group('Achievements.evaluate', () {
    final fixedNow = DateTime(2026, 4, 28, 10, 0);

    test('first hand unlocks first_hand only', () {
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        now: fixedNow,
      );
      final unlocked = next.where((a) => a.isUnlocked).map((a) => a.definitionId);
      expect(unlocked, ['first_hand']);
    });

    test('ten hands unlocks first_hand + ten_hands', () {
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 10),
        now: fixedNow,
      );
      final unlocked = next
          .where((a) => a.isUnlocked)
          .map((a) => a.definitionId)
          .toSet();
      expect(unlocked, containsAll({'first_hand', 'ten_hands'}));
      expect(unlocked.contains('hundred_hands'), isFalse);
    });

    test('hundred hands unlocks all milestone tiers', () {
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 100),
        now: fixedNow,
      );
      final unlocked = next.where((a) => a.isUnlocked).map((a) => a.definitionId);
      expect(unlocked, containsAll({'first_hand', 'ten_hands', 'hundred_hands'}));
    });

    test('showdown win unlocks first_showdown_win', () {
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        ctx: const AchievementContext(wonShowdown: true),
        now: fixedNow,
      );
      final ids = next.where((a) => a.isUnlocked).map((a) => a.definitionId);
      expect(ids, contains('first_showdown_win'));
    });

    test('underdog win requires both wonShowdown and riverEquity < 0.4', () {
      // Winning but with high equity → no underdog.
      final notUnderdog = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        ctx: const AchievementContext(wonShowdown: true, riverEquity: 0.7),
        now: fixedNow,
      );
      expect(
        notUnderdog
            .where((a) => a.definitionId == 'underdog_win')
            .first
            .isUnlocked,
        isFalse,
      );

      final underdog = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        ctx: const AchievementContext(wonShowdown: true, riverEquity: 0.32),
        now: fixedNow,
      );
      expect(
        underdog
            .where((a) => a.definitionId == 'underdog_win')
            .first
            .isUnlocked,
        isTrue,
      );
    });

    test('isNuts unlocks nutted', () {
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        ctx: const AchievementContext(isNuts: true),
        now: fixedNow,
      );
      final nutted =
          next.firstWhere((a) => a.definitionId == 'nutted');
      expect(nutted.isUnlocked, isTrue);
    });

    test('lesson tiers unlock at thresholds', () {
      final one = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(lessons: 1),
        now: fixedNow,
      );
      expect(
        one.firstWhere((a) => a.definitionId == 'first_lesson').isUnlocked,
        isTrue,
      );
      expect(
        one.firstWhere((a) => a.definitionId == 'three_lessons').isUnlocked,
        isFalse,
      );

      final three = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(lessons: 3),
        now: fixedNow,
      );
      expect(
        three.firstWhere((a) => a.definitionId == 'three_lessons').isUnlocked,
        isTrue,
      );
    });

    test('streak transitions unlock streak_3 / streak_7', () {
      final s3 = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1, streak: 3),
        now: fixedNow,
      );
      expect(
        s3.firstWhere((a) => a.definitionId == 'streak_3').isUnlocked,
        isTrue,
      );
      expect(
        s3.firstWhere((a) => a.definitionId == 'streak_7').isUnlocked,
        isFalse,
      );

      final s7 = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1, streak: 7),
        now: fixedNow,
      );
      expect(
        s7.firstWhere((a) => a.definitionId == 'streak_7').isUnlocked,
        isTrue,
      );
    });

    test('best streak counts toward streak achievements', () {
      // Player had a 3-day streak in the past but their current streak broke.
      final next = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1, streak: 1, bestStreak: 3),
        now: fixedNow,
      );
      expect(
        next.firstWhere((a) => a.definitionId == 'streak_3').isUnlocked,
        isTrue,
      );
    });

    test('already-unlocked achievements are preserved unchanged', () {
      final initialTs = DateTime(2026, 4, 1);
      final priming = Achievements.defaults().map((a) {
        if (a.definitionId == 'first_hand') {
          return a.copyWith(unlockedAt: initialTs);
        }
        return a;
      }).toList();
      final next = Achievements.evaluate(
        current: priming,
        stats: _stats(hands: 50),
        now: fixedNow,
      );
      final firstHand =
          next.firstWhere((a) => a.definitionId == 'first_hand');
      expect(firstHand.unlockedAt, initialTs);
    });

    test('newlyUnlocked diff returns only fresh transitions', () {
      final prev = Achievements.evaluate(
        current: Achievements.defaults(),
        stats: _stats(hands: 1),
        now: fixedNow,
      );
      final next = Achievements.evaluate(
        current: prev,
        stats: _stats(hands: 10),
        now: fixedNow.add(const Duration(hours: 1)),
      );
      final fresh = Achievements.newlyUnlocked(prev: prev, next: next);
      expect(fresh.map((a) => a.definitionId), ['ten_hands']);
    });
  });

  group('JSON round-trip', () {
    test('encodeList → tryDecodeList preserves unlock state', () {
      final list = Achievements.defaults();
      final unlockedAt = DateTime(2026, 4, 28, 12, 0);
      list[0] = list[0].copyWith(unlockedAt: unlockedAt);
      final decoded = Achievement.tryDecodeList(Achievement.encodeList(list));
      expect(decoded, isNotNull);
      expect(decoded!.first.definitionId, list.first.definitionId);
      expect(decoded.first.unlockedAt, unlockedAt);
    });

    test('tryDecodeList returns null for invalid input', () {
      expect(Achievement.tryDecodeList(null), isNull);
      expect(Achievement.tryDecodeList(''), isNull);
      expect(Achievement.tryDecodeList('not json'), isNull);
    });
  });
}
