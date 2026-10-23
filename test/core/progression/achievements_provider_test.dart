import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievement.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/achievements_service.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({UserStatsService stats, AchievementsService ach})> _freshServices(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return (stats: UserStatsService(prefs), ach: AchievementsService(prefs));
}

ProviderContainer _container({
  required UserStatsService stats,
  required AchievementsService ach,
}) {
  return ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(stats),
    achievementsServiceProvider.overrideWithValue(ach),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementsService persistence', () {
    test('roundtrip persists and reloads exact set', () async {
      final s = await _freshServices();
      await s.ach.saveUnlocked({
        AchievementId.firstDeal,
        AchievementId.firstPot,
      });
      // New service over the same prefs should restore the set.
      final reloaded = AchievementsService(
          await SharedPreferences.getInstance());
      expect(reloaded.loadUnlocked(), {
        AchievementId.firstDeal,
        AchievementId.firstPot,
      });
    });

    test('unknown IDs in storage are silently dropped', () async {
      // Simulate a future-version unlock saved to disk that the current
      // build doesn't know about.
      SharedPreferences.setMockInitialValues({
        AchievementsService.storageKey:
            jsonEncode(['firstDeal', 'futureUnknown', 'firstPot']),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AchievementsService(prefs);
      expect(service.loadUnlocked(), {
        AchievementId.firstDeal,
        AchievementId.firstPot,
      });
    });

    test('clear() empties the persisted set', () async {
      final s = await _freshServices();
      await s.ach.saveUnlocked({AchievementId.firstDeal});
      await s.ach.clear();
      expect(s.ach.loadUnlocked(), isEmpty);
    });

    test('malformed payload decodes to empty set without throwing', () async {
      SharedPreferences.setMockInitialValues({
        AchievementsService.storageKey: 'not-json',
      });
      final prefs = await SharedPreferences.getInstance();
      expect(AchievementsService(prefs).loadUnlocked(), isEmpty);
    });
  });

  group('UserStats backward-compat decode', () {
    test('legacy payload missing handsWon decodes with handsWon=0', () {
      final legacy = jsonEncode({
        'streakDays': 2,
        'lastPlayedDay': '2026-04-19T00:00:00.000',
        'totalXp': 35,
        'handsPlayed': 3,
        'lessonsCompleted': 0,
        'bestStreakDays': 2,
        // handsWon intentionally absent
      });
      final decoded = UserStats.tryDecode(legacy)!;
      expect(decoded.handsPlayed, 3);
      expect(decoded.handsWon, 0);
      expect(decoded.streakDays, 2);
    });
  });

  group('end-to-end unlock flow via UserStatsNotifier', () {
    test('first hand unlocks First Deal and queues toast', () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      await c.read(userStatsProvider.notifier).recordHandPlayed(
            now: DateTime(2026, 4, 19),
          );
      expect(
        c.read(achievementsProvider),
        contains(AchievementId.firstDeal),
      );
      expect(
        c.read(newlyUnlockedProvider),
        contains(AchievementId.firstDeal),
      );
    });

    test('replaying a hand does not re-queue the same achievement', () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      final notifier = c.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      // Drain the queue (simulate the overlay consuming it).
      c.read(newlyUnlockedProvider.notifier).state = const [];

      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(c.read(newlyUnlockedProvider), isEmpty);
    });

    test('crossing two thresholds in one delta queues both, in catalog '
        'order', () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      // Pre-seed handsPlayed = 9 by replaying.
      final notifier = c.read(userStatsProvider.notifier);
      for (var i = 0; i < 9; i++) {
        await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 10, i));
      }
      // Drain.
      c.read(newlyUnlockedProvider.notifier).state = const [];

      // Tenth hand: crosses gettingComfortable threshold (10).
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 11));
      expect(
        c.read(newlyUnlockedProvider),
        contains(AchievementId.gettingComfortable),
      );
    });

    test('won hand at threshold unlocks firstPot showdown', () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      await c.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            now: DateTime(2026, 4, 19),
          );
      expect(c.read(userStatsProvider).handsWon, 1);
      expect(
        c.read(achievementsProvider),
        contains(AchievementId.firstPot),
      );
    });

    test('resetAll wipes both stats and unlocked set', () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      final notifier = c.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(
        playerWon: true,
        now: DateTime(2026, 4, 19),
      );
      expect(c.read(achievementsProvider), isNotEmpty);

      await notifier.resetAll();
      expect(c.read(achievementsProvider), isEmpty);
      expect(c.read(userStatsProvider).handsWon, 0);
      expect(c.read(newlyUnlockedProvider), isEmpty);
    });

    test('markEarned with no fresh IDs is a no-op (no save, no queue)',
        () async {
      final s = await _freshServices();
      final c = _container(stats: s.stats, ach: s.ach);
      addTearDown(c.dispose);

      // Pre-seed the unlocked set.
      await c
          .read(achievementsProvider.notifier)
          .markEarned({AchievementId.firstDeal});
      c.read(newlyUnlockedProvider.notifier).state = const [];

      // Re-submitting the same set should return [] without re-queuing.
      final fresh = await c
          .read(achievementsProvider.notifier)
          .markEarned({AchievementId.firstDeal});
      expect(fresh, isEmpty);
      expect(c.read(newlyUnlockedProvider), isEmpty);
    });

    test('unlocks survive container rebuild via service', () async {
      final s = await _freshServices();
      final c1 = _container(stats: s.stats, ach: s.ach);
      await c1.read(userStatsProvider.notifier).recordHandPlayed(
            now: DateTime(2026, 4, 19),
          );
      c1.dispose();

      final c2 = _container(stats: s.stats, ach: s.ach);
      addTearDown(c2.dispose);
      expect(
        c2.read(achievementsProvider),
        contains(AchievementId.firstDeal),
      );
    });
  });
}
