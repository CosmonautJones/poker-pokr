import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  group('UserStatsNotifier', () {
    test('recordHandPlayed awards base XP + daily bonus on first play',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(
        playerWon: false,
        now: DateTime(2026, 4, 19, 10, 0),
      );
      final stats = container.read(userStatsProvider);
      expect(stats.streakDays, 1);
      expect(stats.handsPlayed, 1);
      expect(
        stats.totalXp,
        Progression.xpPerHand + Progression.xpDailyBonus,
      );
      expect(stats.bestStreakDays, 1);
    });

    test('recordHandPlayed with playerWon adds win bonus', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            now: DateTime(2026, 4, 19),
          );
      final stats = container.read(userStatsProvider);
      expect(
        stats.totalXp,
        Progression.xpPerHand +
            Progression.xpPerHandWin +
            Progression.xpDailyBonus,
      );
    });

    test('same-day replay does not re-award daily bonus', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 10));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 20));
      final stats = container.read(userStatsProvider);
      // First: hand XP + daily bonus. Second: hand XP only.
      expect(
        stats.totalXp,
        Progression.xpPerHand * 2 + Progression.xpDailyBonus,
      );
      expect(stats.streakDays, 1);
      expect(stats.handsPlayed, 2);
    });

    test('two consecutive days grants two daily bonuses and streak=2',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 20));
      final stats = container.read(userStatsProvider);
      expect(stats.streakDays, 2);
      expect(stats.bestStreakDays, 2);
      expect(
        stats.totalXp,
        Progression.xpPerHand * 2 + Progression.xpDailyBonus * 2,
      );
    });

    test('recordLessonComplete awards lesson XP + daily bonus', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 19));
      final stats = container.read(userStatsProvider);
      expect(stats.lessonsCompleted, 1);
      expect(
        stats.totalXp,
        Progression.xpPerLesson + Progression.xpDailyBonus,
      );
    });

    test('stats persist across rebuilds via service', () async {
      final service = await _freshService();
      final container1 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      await container1
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 19));
      container1.dispose();

      // Fresh container, same service → must restore state from disk.
      final container2 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container2.dispose);
      final stats = container2.read(userStatsProvider);
      expect(stats.lessonsCompleted, 1);
      expect(
        stats.totalXp,
        Progression.xpPerLesson + Progression.xpDailyBonus,
      );
    });

    test('resetAll clears stats', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.resetAll();
      final stats = container.read(userStatsProvider);
      expect(stats.totalXp, 0);
      expect(stats.streakDays, 0);
      expect(stats.handsPlayed, 0);
      expect(stats.lastPlayedDay, isNull);
    });

    test('gap in days resets streak to 1', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 20));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 21));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 25));
      final stats = container.read(userStatsProvider);
      expect(stats.streakDays, 1);
      expect(stats.bestStreakDays, 3);
      expect(stats.handsPlayed, 4);
    });
  });

  group('Achievement unlock integration', () {
    test('first hand unlocks welcome trophy and enqueues it', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container.read(userStatsProvider.notifier).recordHandPlayed(
            now: DateTime(2026, 4, 19),
          );
      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievements.containsKey('grind_first_hand'),
          isTrue);

      final queue = container.read(pendingAchievementUnlocksProvider);
      expect(queue, contains('grind_first_hand'));
    });

    test('popNext drains the queue in FIFO order', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Play 10 hands same day to cross grind_first_hand + grind_hands_10.
      final notifier = container.read(userStatsProvider.notifier);
      for (int i = 0; i < 10; i++) {
        await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 10, i));
      }
      final queue = container.read(pendingAchievementUnlocksProvider);
      expect(queue.first, 'grind_first_hand');
      expect(queue, contains('grind_hands_10'));

      final pendingNotifier =
          container.read(pendingAchievementUnlocksProvider.notifier);
      expect(pendingNotifier.popNext(), 'grind_first_hand');
      // Remaining queue no longer has the popped head.
      expect(
        container.read(pendingAchievementUnlocksProvider),
        isNot(contains('grind_first_hand')),
      );
    });

    test('second event does not re-enqueue already-unlocked trophy', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      // Drain + clear the queue so we observe only fresh emissions.
      container
          .read(pendingAchievementUnlocksProvider.notifier)
          .clear();

      // Play another hand on the SAME day: no threshold crossed.
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 12));
      expect(container.read(pendingAchievementUnlocksProvider), isEmpty);
    });

    test(
      'silent backfill: pre-existing progression unlocks without enqueueing',
      () async {
        // Persist stats with non-empty progression and empty unlocks map —
        // simulates an existing user upgrading into this feature.
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service = UserStatsService(prefs);
        final legacy = UserStats(
          streakDays: 3,
          lastPlayedDay: DateTime(2026, 4, 19),
          totalXp: 60,
          handsPlayed: 12,
          lessonsCompleted: 1,
          bestStreakDays: 3,
        );
        await service.saveStats(legacy);

        final container = ProviderContainer(overrides: [
          userStatsServiceProvider.overrideWithValue(service),
        ]);
        addTearDown(container.dispose);

        final stats = container.read(userStatsProvider);
        // Backfill populates unlocks for already-earned trophies...
        expect(stats.unlockedAchievements, isNotEmpty);
        expect(stats.unlockedAchievements.containsKey('grind_first_hand'),
            isTrue);
        expect(stats.unlockedAchievements.containsKey('grind_hands_10'),
            isTrue);
        expect(stats.unlockedAchievements.containsKey('streak_days_3'),
            isTrue);
        // ...but the toast queue must stay empty (no spam on upgrade).
        expect(container.read(pendingAchievementUnlocksProvider), isEmpty);
      },
    );

    test('resetAll clears unlocks + pending queue', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(container.read(userStatsProvider).unlockedAchievements,
          isNotEmpty);
      expect(container.read(pendingAchievementUnlocksProvider), isNotEmpty);

      await notifier.resetAll();
      expect(
        container.read(userStatsProvider).unlockedAchievements,
        isEmpty,
      );
      expect(container.read(pendingAchievementUnlocksProvider), isEmpty);
    });
  });

  group('HapticsPrefNotifier', () {
    test('defaults to enabled=true when pref is unset', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      expect(container.read(hapticsEnabledProvider), isTrue);
    });

    test('set() persists and flips state', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      await container.read(hapticsEnabledProvider.notifier).set(false);
      expect(container.read(hapticsEnabledProvider), isFalse);
      expect(service.loadHapticsEnabled(), isFalse);
    });
  });
}
