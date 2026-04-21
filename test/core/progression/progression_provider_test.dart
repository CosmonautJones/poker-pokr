import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
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
      expect(stats.unlockedAchievementIds, isEmpty);
      expect(stats.seenAchievementIds, isEmpty);
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

  group('Achievements integration', () {
    test('first hand unlocks first_hand and surfaces in pending queue',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));

      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievementIds, contains('first_hand'));
      expect(stats.seenAchievementIds, isEmpty);

      final pending = container.read(pendingAchievementsProvider);
      expect(pending.map((a) => a.id), contains('first_hand'));
    });

    test('hands threshold unlocks hands_5 after five hands', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      for (int i = 0; i < 5; i++) {
        await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 9 + i));
      }
      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievementIds, contains('hands_5'));
    });

    test('recordLessonComplete unlocks first_lesson', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 19));
      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievementIds, contains('first_lesson'));
    });

    test('markAchievementsSeen removes entries from pending derivation',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(
        container
            .read(pendingAchievementsProvider)
            .map((a) => a.id),
        contains('first_hand'),
      );

      await notifier.markAchievementsSeen(['first_hand']);
      final stats = container.read(userStatsProvider);
      expect(stats.seenAchievementIds, contains('first_hand'));
      expect(
        container
            .read(pendingAchievementsProvider)
            .map((a) => a.id),
        isNot(contains('first_hand')),
      );
    });

    test('markAchievementsSeen is idempotent + persists across rebuild',
        () async {
      final service = await _freshService();
      final container1 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      final n1 = container1.read(userStatsProvider.notifier);
      await n1.recordHandPlayed(now: DateTime(2026, 4, 19));
      await n1.markAchievementsSeen(['first_hand']);
      // Second call is a no-op on state.
      await n1.markAchievementsSeen(['first_hand']);
      container1.dispose();

      final container2 = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container2.dispose);
      final stats = container2.read(userStatsProvider);
      expect(stats.seenAchievementIds, contains('first_hand'));
      expect(
        container2.read(pendingAchievementsProvider),
        isEmpty,
      );
    });

    test('pending queue preserves catalog order', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      // Five hands on the same day: both first_hand and hands_5 unlock here.
      for (int i = 0; i < 5; i++) {
        await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 9 + i));
      }
      final pending = container.read(pendingAchievementsProvider);
      final ids = pending.map((a) => a.id).toList();
      expect(ids, containsAll(<String>['first_hand', 'hands_5']));
      expect(
        ids.indexOf('first_hand'),
        lessThan(ids.indexOf('hands_5')),
        reason: 'catalog declares first_hand before hands_5',
      );
    });

    test('pending entries carry full Achievement metadata', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));
      final pending = container.read(pendingAchievementsProvider);
      final firstHand = pending.firstWhere((a) => a.id == 'first_hand');
      expect(firstHand.rarity, AchievementRarity.common);
      expect(firstHand.title.isNotEmpty, isTrue);
      expect(firstHand.description.isNotEmpty, isTrue);
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
