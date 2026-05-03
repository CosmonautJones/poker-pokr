import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/daily_challenge.dart';
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

    test('recordHandPlayed returns newly-unlocked achievement ids', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      final unlocks = await notifier.recordHandPlayed(
        playerWon: true,
        now: DateTime(2026, 4, 19),
      );
      // First-hand + first-win unlock together on the very first call.
      expect(unlocks, containsAll(<String>['first_hand', 'first_win']));
      final stats = container.read(userStatsProvider);
      expect(stats.unlockedAchievements, containsAll(<String>[
        'first_hand',
        'first_win',
      ]));
      expect(stats.lifetimeWins, 1);
    });

    test('second hand returns no duplicate unlocks', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      final second = await notifier.recordHandPlayed(
        now: DateTime(2026, 4, 19, 11),
      );
      expect(second, isNot(contains('first_hand')));
    });

    test('recordDailyChallengeIfMatch only ticks for today\'s pick',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);
      final notifier = container.read(userStatsProvider.notifier);
      final now = DateTime(2026, 5, 3, 10);
      final today = challengeFor(now)!;

      // Wrong scenario id → no-op.
      await notifier.recordDailyChallengeIfMatch(
        lessonId: 'definitely_not_a_lesson',
        scenarioIndex: 0,
        now: now,
      );
      expect(container.read(userStatsProvider).dailyChallengesCompleted, 0);

      // Matching id → tick.
      await notifier.recordDailyChallengeIfMatch(
        lessonId: today.lessonId,
        scenarioIndex: today.scenarioIndex,
        now: now,
      );
      var stats = container.read(userStatsProvider);
      expect(stats.dailyChallengesCompleted, 1);
      expect(stats.dailyChallengeDoneOn(now), isTrue);

      // Second call same day → idempotent no-op.
      await notifier.recordDailyChallengeIfMatch(
        lessonId: today.lessonId,
        scenarioIndex: today.scenarioIndex,
        now: now.add(const Duration(hours: 5)),
      );
      stats = container.read(userStatsProvider);
      expect(stats.dailyChallengesCompleted, 1);
    });

    test('pendingUnlocksProvider receives ids and pops empty after drain',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(
        playerWon: true,
        now: DateTime(2026, 4, 19),
      );
      final pending = container.read(pendingUnlocksProvider);
      expect(pending, containsAll(<String>['first_hand', 'first_win']));

      final drained = container
          .read(pendingUnlocksProvider.notifier)
          .popAll();
      expect(drained, isNotEmpty);
      expect(container.read(pendingUnlocksProvider), isEmpty);
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
