import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
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

  group('AchievementsAlgorithm.evaluate', () {
    test('empty stats unlocks nothing', () {
      expect(
        AchievementsAlgorithm.evaluate(const UserStats.empty()),
        isEmpty,
      );
    });

    test('one hand unlocks firstHand only', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 10,
        handsPlayed: 1,
        lessonsCompleted: 0,
        handsWon: 0,
        bestStreakDays: 1,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.firstHand));
      expect(unlocked.length, 1);
    });

    test('100 hands unlocks Centurion + firstHand', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 1000,
        handsPlayed: 100,
        lessonsCompleted: 0,
        handsWon: 0,
        bestStreakDays: 1,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.firstHand));
      expect(unlocked, contains(AchievementId.hundredHands));
    });

    test('5-day best streak unlocks Daily Habit', () {
      const stats = UserStats(
        streakDays: 5,
        lastPlayedDay: null,
        totalXp: 100,
        handsPlayed: 1,
        lessonsCompleted: 0,
        handsWon: 0,
        bestStreakDays: 5,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.fiveDayStreak));
      expect(
        unlocked.contains(AchievementId.tenDayStreak),
        isFalse,
      );
    });

    test('lessonsCompleted=10 unlocks both lesson tiers', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 0,
        lessonsCompleted: 10,
        handsWon: 0,
        bestStreakDays: 1,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.lessonGraduate));
      expect(unlocked, contains(AchievementId.perfectionist));
    });

    test('handsWon=10 unlocks Showdown Slayer', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 10,
        lessonsCompleted: 0,
        handsWon: 10,
        bestStreakDays: 1,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.showdownSlayer));
    });

    test('level 5 (1250 XP) unlocks Rising Star', () {
      const stats = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 1250,
        handsPlayed: 1,
        lessonsCompleted: 0,
        handsWon: 0,
        bestStreakDays: 1,
      );
      final unlocked = AchievementsAlgorithm.evaluate(stats);
      expect(unlocked, contains(AchievementId.levelFive));
    });
  });

  group('AchievementsAlgorithm.definition', () {
    test('returns the catalog entry for every enum value', () {
      for (final id in AchievementId.values) {
        expect(AchievementsAlgorithm.definition(id), isNotNull);
      }
    });
  });

  group('AchievementsNotifier', () {
    test('newly-recorded hand pushes pending unlock for firstHand',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Initialize achievements notifier (no unlocks yet).
      final achNotifier =
          container.read(achievementsProvider.notifier);
      expect(container.read(achievementsProvider), isEmpty);
      expect(achNotifier.drainPendingUnlocks(), isEmpty);

      // Record a hand → triggers re-evaluation via ref.listen.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));

      // Allow microtasks (the listener uses async write).
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(achievementsProvider),
        contains(AchievementId.firstHand),
      );
      final pending = achNotifier.drainPendingUnlocks();
      expect(pending, contains(AchievementId.firstHand));
    });

    test('pre-existing stats reconcile silently (no pending unlocks)',
        () async {
      // Seed UserStats persistence so build() reads non-empty stats.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = UserStatsService(prefs);
      const seeded = UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 100,
        handsPlayed: 5,
        lessonsCompleted: 0,
        handsWon: 0,
        bestStreakDays: 1,
      );
      await service.saveStats(seeded);

      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // First read evaluates against seeded stats and merges into persisted.
      final unlocked = container.read(achievementsProvider);
      expect(unlocked, contains(AchievementId.firstHand));
      // But no banner-pending diff because it was reconciliation, not a
      // live change.
      final pending =
          container.read(achievementsProvider.notifier).drainPendingUnlocks();
      expect(pending, isEmpty);
    });

    test('resetAll clears persisted unlocks', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      // Force an unlock first.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(achievementsProvider), isNotEmpty);

      await container.read(achievementsProvider.notifier).resetAll();
      expect(container.read(achievementsProvider), isEmpty);
      expect(service.loadAchievements(), isEmpty);
    });
  });
}
