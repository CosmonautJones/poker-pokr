import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements_catalog.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

ProviderContainer _container(UserStatsService service) {
  return ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(service),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Achievement unlock pipeline', () {
    test('first hand unlocks first_hand and enqueues a toast', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));

      final unlocks = container.read(unlockedAchievementsProvider);
      expect(unlocks.contains('first_hand'), isTrue);

      final pending = container.read(pendingAchievementToastsProvider);
      expect(pending.map((a) => a.id), contains('first_hand'));
    });

    test('replaying same day does not re-enqueue an already unlocked toast',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 10));
      // Drain the queue (the UI would dequeue after showing each toast).
      final toastNotifier =
          container.read(pendingAchievementToastsProvider.notifier);
      while (container.read(pendingAchievementToastsProvider).isNotEmpty) {
        toastNotifier.dismissCurrent();
      }
      // Replay another hand same day.
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 22));

      final pending = container.read(pendingAchievementToastsProvider);
      expect(
        pending.map((a) => a.id),
        isNot(contains('first_hand')),
        reason: 'already-unlocked achievement must not re-enqueue',
      );
    });

    test('crossing streak=3 across 3 days enqueues streak_3', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 20));
      // streak_3 should fire on this third consecutive day.
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 21));

      final unlocks = container.read(unlockedAchievementsProvider);
      expect(unlocks.contains('streak_3'), isTrue);

      final pendingIds = container
          .read(pendingAchievementToastsProvider)
          .map((a) => a.id)
          .toList();
      expect(pendingIds, contains('streak_3'));
    });

    test('multi-threshold burst enqueues in catalog order', () async {
      // Pre-seed stats so a single recordHandPlayed call crosses both
      // hands_50 (>=50) and xp_1000 (>=1000) in the same _apply pass.
      // hands_50 precedes xp_1000 in the catalog → that's the asserted order.
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = UserStatsService(prefs);
      await service.saveStats(UserStats(
        streakDays: 1,
        lastPlayedDay: DateTime(2026, 4, 18),
        totalXp: 990,
        handsPlayed: 49,
        lessonsCompleted: 0,
        bestStreakDays: 1,
      ));
      final container = _container(service);
      addTearDown(container.dispose);

      // Day-after the seed → +1 hand, +10 hand XP, +10 daily bonus = 1010 XP,
      // 50 hands. Crosses both thresholds in a single update.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));

      final unlocks = container.read(unlockedAchievementsProvider);
      expect(unlocks.contains('hands_50'), isTrue);
      expect(unlocks.contains('xp_1000'), isTrue);

      final pendingIds = container
          .read(pendingAchievementToastsProvider)
          .map((a) => a.id)
          .toList();
      final relevant =
          pendingIds.where((id) => id == 'hands_50' || id == 'xp_1000').toList();
      expect(relevant, equals(['hands_50', 'xp_1000']),
          reason: 'multi-unlock burst must enqueue in catalog order');
    });

    test('lessons_complete fires once the live curriculum is finished',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      for (int i = 0; i < kTotalLessonScenarios; i++) {
        await notifier.recordLessonComplete(
          now: DateTime(2026, 4, 19).add(Duration(days: i)),
        );
      }

      final unlocks = container.read(unlockedAchievementsProvider);
      expect(unlocks.contains('first_lesson'), isTrue);
      expect(unlocks.contains('lessons_complete'), isTrue);
    });

    test('unlock timestamps use the threaded `now` for determinism', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final fixed = DateTime(2026, 4, 19, 14, 30, 12);
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: fixed);

      final unlocks = container.read(unlockedAchievementsProvider);
      expect(unlocks.unlockedAt['first_hand'], fixed);
    });

    test('resetAll clears unlocks and pending queue', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(container.read(unlockedAchievementsProvider).count,
          greaterThan(0));
      expect(container.read(pendingAchievementToastsProvider), isNotEmpty);

      await notifier.resetAll();

      expect(container.read(unlockedAchievementsProvider).count, 0);
      expect(container.read(pendingAchievementToastsProvider), isEmpty);
    });

    test('unlocks persist across container rebuilds', () async {
      final service = await _freshService();
      final c1 = _container(service);
      await c1
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 19));
      expect(c1.read(unlockedAchievementsProvider).contains('first_hand'),
          isTrue);
      c1.dispose();

      final c2 = _container(service);
      addTearDown(c2.dispose);
      expect(c2.read(unlockedAchievementsProvider).contains('first_hand'),
          isTrue);
    });
  });
}
