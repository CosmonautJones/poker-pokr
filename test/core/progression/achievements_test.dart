import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/achievements_service.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(UserStatsService, AchievementsService)> _freshServices() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return (UserStatsService(prefs), AchievementsService(prefs));
}

ProviderContainer _container(
  UserStatsService stats,
  AchievementsService ach,
) {
  return ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(stats),
    achievementsServiceProvider.overrideWithValue(ach),
  ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AchievementsState.evaluateNew', () {
    test('returns ids whose predicate matches and aren\'t yet unlocked', () {
      const stats = UserStats(
        streakDays: 3,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 1,
        lessonsCompleted: 1,
        bestStreakDays: 3,
      );
      const initial = AchievementsState.empty();
      final fresh = initial.evaluateNew(stats);
      expect(fresh, contains('first_hand'));
      expect(fresh, contains('lesson_first'));
      expect(fresh, contains('streak_3'));
      expect(fresh, isNot(contains('hands_50')));
    });

    test('skips ids already in unlocked map', () {
      const stats = UserStats(
        streakDays: 0,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 1,
        lessonsCompleted: 0,
        bestStreakDays: 0,
      );
      final state = AchievementsState(unlocked: {
        'first_hand': DateTime(2026, 1, 1),
      });
      final fresh = state.evaluateNew(stats);
      expect(fresh, isEmpty);
    });
  });

  group('AchievementsState.withUnlocked', () {
    test('stamps timestamp for new ids without overwriting existing', () {
      final ts1 = DateTime(2026, 1, 1);
      final ts2 = DateTime(2026, 6, 1);
      final state = AchievementsState(unlocked: {'first_hand': ts1});
      final next = state.withUnlocked(['first_hand', 'hands_50'], ts2);
      expect(next.unlocked['first_hand'], ts1);
      expect(next.unlocked['hands_50'], ts2);
    });
  });

  group('AchievementsState codec', () {
    test('round-trips through encode/tryDecode', () {
      final ts = DateTime(2026, 4, 30, 12, 34, 56);
      final state = AchievementsState(unlocked: {
        'first_hand': ts,
        'streak_7': ts,
      });
      final restored = AchievementsState.tryDecode(state.encode())!;
      expect(restored.unlocked.length, 2);
      expect(restored.unlocked['first_hand']!.toIso8601String(),
          ts.toIso8601String());
    });

    test('tryDecode returns null on garbage', () {
      expect(AchievementsState.tryDecode(null), isNull);
      expect(AchievementsState.tryDecode(''), isNull);
      expect(AchievementsState.tryDecode('not-json'), isNull);
    });
  });

  group('AchievementsNotifier', () {
    test('cold-start backfill stamps eligible achievements without queueing',
        () async {
      final (statsSvc, achSvc) = await _freshServices();
      // Pre-seed stats so the notifier sees handsPlayed >= 1 at boot.
      await statsSvc.saveStats(const UserStats(
        streakDays: 1,
        lastPlayedDay: null,
        totalXp: 10,
        handsPlayed: 1,
        lessonsCompleted: 0,
        bestStreakDays: 1,
      ));
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      final state = container.read(achievementsProvider);
      expect(state.isUnlocked('first_hand'), isTrue);
      // Backfill must NOT enqueue toasts.
      expect(container.read(pendingUnlockProvider), isNull);
    });

    test('runtime stat changes enqueue new unlocks for the toast layer',
        () async {
      final (statsSvc, achSvc) = await _freshServices();
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      // Force the achievements provider to build once with empty stats so it
      // installs its listener on userStatsProvider.
      expect(container.read(achievementsProvider).unlockedCount, 0);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30));

      final ach = container.read(achievementsProvider);
      expect(ach.isUnlocked('first_hand'), isTrue);
      expect(container.read(pendingUnlockProvider), 'first_hand');
    });

    test('consumeNextPending drains FIFO and clears when empty', () async {
      final (statsSvc, achSvc) = await _freshServices();
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      container.read(achievementsProvider); // build

      // Single event that should unlock first_hand AND streak_3 if streak hits.
      await statsSvc.saveStats(const UserStats(
        streakDays: 3,
        lastPlayedDay: null,
        totalXp: 0,
        handsPlayed: 1,
        lessonsCompleted: 0,
        bestStreakDays: 3,
      ));
      // Trigger a notify by running recordHandPlayed.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30));

      final notifier = container.read(achievementsProvider.notifier);
      final first = notifier.consumeNextPending();
      expect(first, isNotNull);
      // Drain the rest.
      while (notifier.consumeNextPending() != null) {}
      expect(container.read(pendingUnlockProvider), isNull);
    });

    test('repeated stat changes do not re-enqueue already-unlocked ids',
        () async {
      final (statsSvc, achSvc) = await _freshServices();
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      container.read(achievementsProvider);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30));
      // Drain.
      final notifier = container.read(achievementsProvider.notifier);
      while (notifier.consumeNextPending() != null) {}

      // Another hand same day — no new achievements should fire.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30, 22));
      expect(container.read(pendingUnlockProvider), isNull);
    });

    test('resetAll clears unlocks and pending queue and persists', () async {
      final (statsSvc, achSvc) = await _freshServices();
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      container.read(achievementsProvider);
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30));
      expect(container.read(achievementsProvider).unlockedCount, greaterThan(0));

      await container.read(achievementsProvider.notifier).resetAll();
      expect(container.read(achievementsProvider).unlockedCount, 0);
      expect(container.read(pendingUnlockProvider), isNull);
      // Persisted: a fresh service should also see empty.
      expect(achSvc.load().unlockedCount, 0);
    });
  });

  group('AchievementsNotifier — back-to-back changes', () {
    test('two stat changes in the same tick enqueue both unlocks in order',
        () async {
      final (statsSvc, achSvc) = await _freshServices();
      final container = _container(statsSvc, achSvc);
      addTearDown(container.dispose);

      container.read(achievementsProvider);
      final notifier = container.read(achievementsProvider.notifier);

      // First trigger unlocks first_hand (handsPlayed >= 1) plus the streak
      // and lesson floors via a manual pre-seed.
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 4, 30));
      // Second event same day: lesson completion. Should fire lesson_first.
      await container
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 30, 12));

      final ids = <String>[];
      while (true) {
        final id = notifier.consumeNextPending();
        if (id == null) break;
        ids.add(id);
      }
      expect(ids, contains('first_hand'));
      expect(ids, contains('lesson_first'));
      // first_hand fires before lesson_first because of event ordering.
      expect(
        ids.indexOf('first_hand'),
        lessThan(ids.indexOf('lesson_first')),
      );
    });
  });

  group('Progression.projectHandXp', () {
    test('matches the notifier\'s actual award on a first-of-day hand',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UserStatsService(prefs);
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final before = container.read(userStatsProvider);
      final projection = Progression.projectHandXp(
        stats: before,
        playerWon: true,
        now: DateTime(2026, 5, 1, 9),
      );

      await container.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            now: DateTime(2026, 5, 1, 9),
          );
      final after = container.read(userStatsProvider);
      expect(after.totalXp - before.totalXp, projection);
    });

    test('matches the notifier on a second same-day hand (no daily bonus)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final svc = UserStatsService(prefs);
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 5, 1, 9));
      final mid = container.read(userStatsProvider);
      final projection = Progression.projectHandXp(
        stats: mid,
        playerWon: false,
        now: DateTime(2026, 5, 1, 22),
      );
      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(now: DateTime(2026, 5, 1, 22));
      final after = container.read(userStatsProvider);
      expect(after.totalXp - mid.totalXp, projection);
      expect(projection, Progression.xpPerHand);
    });
  });

  group('AchievementCatalog integrity', () {
    test('all ids are unique', () {
      final ids = AchievementCatalog.all.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('categories cover every member of AchievementCategory enum', () {
      for (final c in AchievementCategory.values) {
        expect(AchievementCatalog.inCategory(c), isNotEmpty,
            reason: 'No achievements registered for category $c');
      }
    });
  });
}
