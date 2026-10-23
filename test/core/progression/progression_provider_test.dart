import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

ProviderContainer _container(UserStatsService service) {
  return ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(service),
  ]);
}

/// Sum of `xpPerAchievement * count(achievements newly unlocked)` for a
/// given test scenario. Tests below pass the expected unlock list to keep
/// the math obvious to readers.
int _achievementXp(int unlockCount) =>
    unlockCount * Progression.xpPerAchievement;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStatsNotifier', () {
    test('recordHandPlayed awards base XP + daily bonus + first-hand unlock',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(
        playerWon: false,
        now: DateTime(2026, 4, 19, 10, 0),
      );
      final stats = container.read(userStatsProvider);
      expect(stats.streakDays, 1);
      expect(stats.handsPlayed, 1);
      // First hand also unlocks `first_hand` achievement.
      expect(stats.unlockedAchievementIds, contains('first_hand'));
      expect(
        stats.totalXp,
        Progression.xpPerHand +
            Progression.xpDailyBonus +
            _achievementXp(1),
      );
      expect(stats.bestStreakDays, 1);
    });

    test('recordHandPlayed with playerWon adds win bonus + first_win unlock',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      await container.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            now: DateTime(2026, 4, 19),
          );
      final stats = container.read(userStatsProvider);
      // Two new unlocks expected: first_hand + first_win.
      expect(stats.unlockedAchievementIds, containsAll(<String>{
        'first_hand',
        'first_win',
      }));
      expect(stats.handsWon, 1);
      expect(
        stats.totalXp,
        Progression.xpPerHand +
            Progression.xpPerHandWin +
            Progression.xpDailyBonus +
            _achievementXp(2),
      );
    });

    test('same-day replay does not re-award daily bonus or duplicate unlocks',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 10));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19, 20));
      final stats = container.read(userStatsProvider);

      // First call: hand XP + daily bonus + first_hand unlock.
      // Second call: hand XP only — first_hand already unlocked.
      expect(
        stats.totalXp,
        Progression.xpPerHand * 2 +
            Progression.xpDailyBonus +
            _achievementXp(1),
      );
      expect(stats.streakDays, 1);
      expect(stats.handsPlayed, 2);
      // Only the one unlock from the first play.
      expect(
        stats.unlockedAchievementIds.where((id) => id == 'first_hand').length,
        1,
      );
    });

    test('two consecutive days grants two daily bonuses and streak=2',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 20));
      final stats = container.read(userStatsProvider);
      expect(stats.streakDays, 2);
      expect(stats.bestStreakDays, 2);
      // First unlock: first_hand. No additional unlocks for streak < 3.
      expect(
        stats.totalXp,
        Progression.xpPerHand * 2 +
            Progression.xpDailyBonus * 2 +
            _achievementXp(1),
      );
    });

    test('hot_streak unlocks once 3-day streak is hit', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 19));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 20));
      await notifier.recordHandPlayed(now: DateTime(2026, 4, 21));
      final stats = container.read(userStatsProvider);
      expect(stats.bestStreakDays, 3);
      expect(stats.unlockedAchievementIds, contains('hot_streak'));
    });

    test('big-hand unlock fires when heroHandRankIndex meets threshold',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      // Pass HandRank.flush.index = 5.
      await container.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            heroHandRankIndex: 5,
            now: DateTime(2026, 4, 19),
          );
      final stats = container.read(userStatsProvider);
      expect(stats.bestHandRankIndex, 5);
      expect(stats.unlockedAchievementIds, contains('big_hand_flush'));
      // Higher-tier big-hand achievements stay locked.
      expect(stats.unlockedAchievementIds,
          isNot(contains('big_hand_full_house')));
    });

    test('bestHandRankIndex never decreases on subsequent hands', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      final notifier = container.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(
        heroHandRankIndex: 6, // full house
        now: DateTime(2026, 4, 19),
      );
      // Second hand with weaker holding shouldn't lower the watermark.
      await notifier.recordHandPlayed(
        heroHandRankIndex: 1, // pair
        now: DateTime(2026, 4, 20),
      );
      final stats = container.read(userStatsProvider);
      expect(stats.bestHandRankIndex, 6);
    });

    test('recordLessonComplete awards lesson XP + first_lesson unlock',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 19));
      final stats = container.read(userStatsProvider);
      expect(stats.lessonsCompleted, 1);
      expect(stats.unlockedAchievementIds, contains('first_lesson'));
      expect(
        stats.totalXp,
        Progression.xpPerLesson +
            Progression.xpDailyBonus +
            _achievementXp(1),
      );
    });

    test('newly unlocked achievements queue into pendingUnlocks provider',
        () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(playerWon: true);

      final pending = container.read(pendingAchievementUnlocksProvider);
      // first_hand + first_win surface together.
      expect(pending.length, 2);
      expect(
        pending.map((a) => a.id).toSet(),
        {'first_hand', 'first_win'},
      );
    });

    test('PendingUnlocksNotifier consume pops one at a time', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);

      await container
          .read(userStatsProvider.notifier)
          .recordHandPlayed(playerWon: true);

      final notifier =
          container.read(pendingAchievementUnlocksProvider.notifier);
      expect(notifier.consume(), isNotNull);
      expect(container.read(pendingAchievementUnlocksProvider).length, 1);
      expect(notifier.consume(), isNotNull);
      expect(notifier.consume(), isNull);
      expect(container.read(pendingAchievementUnlocksProvider), isEmpty);
    });

    test('stats persist across rebuilds via service', () async {
      final service = await _freshService();
      final container1 = _container(service);
      await container1
          .read(userStatsProvider.notifier)
          .recordLessonComplete(now: DateTime(2026, 4, 19));
      container1.dispose();

      // Fresh container, same service → must restore state from disk.
      final container2 = _container(service);
      addTearDown(container2.dispose);
      final stats = container2.read(userStatsProvider);
      expect(stats.lessonsCompleted, 1);
      expect(stats.unlockedAchievementIds, contains('first_lesson'));
      expect(
        stats.totalXp,
        Progression.xpPerLesson +
            Progression.xpDailyBonus +
            _achievementXp(1),
      );
    });

    test('resetAll clears stats including unlocks and pending queue',
        () async {
      final service = await _freshService();
      final container = _container(service);
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
      expect(container.read(pendingAchievementUnlocksProvider), isEmpty);
    });

    test('gap in days resets streak to 1', () async {
      final service = await _freshService();
      final container = _container(service);
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
      final container = _container(service);
      addTearDown(container.dispose);
      expect(container.read(hapticsEnabledProvider), isTrue);
    });

    test('set() persists and flips state', () async {
      final service = await _freshService();
      final container = _container(service);
      addTearDown(container.dispose);
      await container.read(hapticsEnabledProvider.notifier).set(false);
      expect(container.read(hapticsEnabledProvider), isFalse);
      expect(service.loadHapticsEnabled(), isFalse);
    });
  });

  group('UserStats decode backward compatibility', () {
    test('old payload without achievement fields decodes to empty defaults',
        () {
      const oldJson = '{"streakDays":2,"totalXp":80,"handsPlayed":3}';
      final decoded = UserStats.tryDecode(oldJson)!;
      expect(decoded.handsWon, 0);
      expect(decoded.bestHandRankIndex, UserStats.noBestHand);
      expect(decoded.unlockedAchievementIds, isEmpty);
      expect(decoded.handsPlayed, 3);
    });

    test('encode/decode roundtrip preserves achievement ids', () {
      final stats = const UserStats.empty().copyWith(
        handsPlayed: 5,
        handsWon: 2,
        bestHandRankIndex: 6,
        unlockedAchievementIds: <String>{'first_hand', 'first_win'},
      );
      final decoded = UserStats.tryDecode(stats.encode())!;
      expect(decoded.handsWon, 2);
      expect(decoded.bestHandRankIndex, 6);
      expect(decoded.unlockedAchievementIds,
          equals(<String>{'first_hand', 'first_win'}));
    });

    test('catalog ids referenced by predicates exist (sanity)', () {
      // Ensures we don't ship a typo in the catalog. The full predicates
      // are exercised by achievements_test.dart.
      expect(AchievementsCatalog.byId('first_hand'), isNotNull);
      expect(AchievementsCatalog.byId('first_win'), isNotNull);
      expect(AchievementsCatalog.byId('hot_streak'), isNotNull);
      expect(AchievementsCatalog.byId('first_lesson'), isNotNull);
      expect(AchievementsCatalog.byId('big_hand_flush'), isNotNull);
    });
  });
}
