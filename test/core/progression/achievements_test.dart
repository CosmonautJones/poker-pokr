import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement_state.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Achievement.evaluateAll', () {
    test('returns no ids for empty stats', () {
      final ids = Achievement.evaluateAll(const UserStats.empty());
      expect(ids, isEmpty);
    });

    test('after 1 hand: first_hand unlocked, ten_hands not', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 1);
      final ids = Achievement.evaluateAll(stats);
      expect(ids, contains('first_hand'));
      expect(ids, isNot(contains('ten_hands')));
    });

    test('after 10 hands: first_hand and ten_hands both unlocked', () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 10);
      final ids = Achievement.evaluateAll(stats);
      expect(ids, containsAll(<String>['first_hand', 'ten_hands']));
      expect(ids, isNot(contains('hundred_hands')));
    });

    test('streak_3 unlocks via bestStreakDays even if streakDays drops', () {
      final stats = const UserStats.empty().copyWith(
        streakDays: 1,
        bestStreakDays: 3,
      );
      final ids = Achievement.evaluateAll(stats);
      expect(ids, contains('streak_3'));
      expect(ids, isNot(contains('streak_7')));
    });

    test('1250 totalXp → level 5 → level_5 unlocked', () {
      final stats = const UserStats.empty().copyWith(totalXp: 1250);
      expect(stats.level, 5);
      final ids = Achievement.evaluateAll(stats);
      expect(ids, contains('level_2'));
      expect(ids, contains('level_5'));
      expect(ids, isNot(contains('level_10')));
    });

    test('Achievement.byId returns the catalog entry', () {
      expect(Achievement.byId('first_hand')?.title, 'First Hand');
      expect(Achievement.byId('does_not_exist'), isNull);
    });
  });

  group('Achievement.pickNext', () {
    test('returns null when every achievement is unlocked', () {
      final everyId = Achievement.evaluateAll(
        const UserStats.empty().copyWith(
          handsPlayed: 1000,
          lessonsCompleted: 100,
          totalXp: 100000,
          bestStreakDays: 100,
        ),
      );
      final unlocked = <String, DateTime>{
        for (final id in everyId) id: DateTime(2026, 1, 1),
      };
      final state = AchievementState(unlockedAt: unlocked);
      final next = Achievement.pickNext(const UserStats.empty(), state);
      expect(next, isNull);
    });

    test('prefers the highest non-zero progress fraction', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 5,
        lessonsCompleted: 1,
      );
      final next = Achievement.pickNext(stats, const AchievementState.empty());
      expect(next?.id, 'first_hand');
    });

    test(
        'when first_hand is already unlocked, picks the next-best in-progress',
        () {
      final stats = const UserStats.empty().copyWith(handsPlayed: 5);
      final state = AchievementState(unlockedAt: {
        'first_hand': DateTime(2026, 1, 1),
      });
      final next = Achievement.pickNext(stats, state);
      expect(next?.id, 'ten_hands');
    });

    test('falls back to lowest-target locked when nothing has progress', () {
      final next = Achievement.pickNext(
        const UserStats.empty(),
        const AchievementState.empty(),
      );
      expect(next, isNotNull);
      expect(next!.target, 1);
    });
  });

  group('AchievementState serialization', () {
    test('encode / decode preserves unlockedAt timestamps within seconds', () {
      final t1 = DateTime(2026, 4, 19, 12, 30, 45);
      final t2 = DateTime(2026, 4, 20, 9, 15, 0);
      final original = AchievementState(unlockedAt: {
        'first_hand': t1,
        'streak_3': t2,
      });
      final decoded = AchievementState.tryDecode(original.encode())!;
      expect(decoded.unlockedAt.length, 2);
      expect(
        decoded.unlockedAt['first_hand']!.difference(t1).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
      expect(
        decoded.unlockedAt['streak_3']!.difference(t2).inSeconds.abs(),
        lessThanOrEqualTo(1),
      );
    });

    test('tryDecode tolerates garbage / null / empty', () {
      expect(AchievementState.tryDecode(null), isNull);
      expect(AchievementState.tryDecode(''), isNull);
      expect(AchievementState.tryDecode('not json'), isNull);
    });

    test('tryDecode silently drops entries with non-parseable values', () {
      const raw =
          '{"unlockedAt":{"first_hand":"2026-04-19T10:00:00.000",'
          '"bad_value":"not-a-date","numeric":42}}';
      final decoded = AchievementState.tryDecode(raw)!;
      expect(decoded.unlockedAt.keys, ['first_hand']);
    });

    test('copyWithNewUnlocks ignores ids already present', () {
      final earlier = DateTime(2026, 4, 19);
      final later = DateTime(2026, 4, 25);
      final initial =
          AchievementState(unlockedAt: {'first_hand': earlier});
      final next = initial.copyWithNewUnlocks({
        'first_hand': later,
        'ten_hands': later,
      });
      expect(next.unlockedAt['first_hand'], earlier);
      expect(next.unlockedAt['ten_hands'], later);
    });
  });

  group('Achievement unlock detection inside UserStatsNotifier', () {
    test(
        'crossing the 10-hand boundary fires ten_hands once even after more '
        'hands are played', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      final base = DateTime(2026, 4, 19, 10);
      // Play 10 hands on the same day to cross both first_hand and ten_hands.
      for (int i = 0; i < 10; i++) {
        await notifier.recordHandPlayed(now: base.add(Duration(minutes: i)));
      }
      final firstQueue =
          List<Achievement>.from(container.read(recentlyUnlockedAchievementsProvider));
      expect(
        firstQueue.map((a) => a.id),
        containsAll(<String>['first_hand', 'ten_hands']),
      );
      // Drain the queue as the UI would.
      container.read(recentlyUnlockedAchievementsProvider.notifier).clear();

      // Play more hands past the boundary — no new ten_hands event.
      for (int i = 0; i < 3; i++) {
        await notifier.recordHandPlayed(
          now: base.add(Duration(minutes: 60 + i)),
        );
      }
      final secondQueue =
          List<Achievement>.from(container.read(recentlyUnlockedAchievementsProvider));
      expect(secondQueue, isEmpty);

      // Persisted state should still hold the unlock entries.
      final persisted = container.read(achievementStateProvider);
      expect(persisted.isUnlocked('first_hand'), isTrue);
      expect(persisted.isUnlocked('ten_hands'), isTrue);
    });

    test('resetAll clears achievement state alongside user stats', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordLessonComplete(now: DateTime(2026, 4, 19));
      expect(
        container.read(achievementStateProvider).isUnlocked('first_lesson'),
        isTrue,
      );

      await notifier.resetAll();
      expect(container.read(userStatsProvider).totalXp, 0);
      expect(
        container.read(achievementStateProvider).unlockedCount,
        0,
      );
      expect(
        container.read(recentlyUnlockedAchievementsProvider),
        isEmpty,
      );

      // Service-level persistence should also be cleared.
      expect(service.loadAchievements().unlockedCount, 0);
    });

    test('RecentUnlocksNotifier dedupes by id when push is called twice',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final recent = container.read(recentlyUnlockedAchievementsProvider.notifier);
      final a = Achievement.byId('first_hand')!;
      recent.push(a);
      recent.push(a);
      expect(container.read(recentlyUnlockedAchievementsProvider).length, 1);
    });

    test('persisted unlocks survive container rebuild', () async {
      final service = await _freshService();
      final c1 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      await c1
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(c1.read(achievementStateProvider).isUnlocked('first_hand'), isTrue);
      c1.dispose();

      final c2 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(c2.dispose);
      expect(c2.read(achievementStateProvider).isUnlocked('first_hand'), isTrue);
    });
  });
}
