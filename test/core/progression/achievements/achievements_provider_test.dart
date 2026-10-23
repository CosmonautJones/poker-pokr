import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements/achievement_event.dart';
import 'package:poker_trainer/core/progression/achievements_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:poker_trainer/poker/engine/hand_evaluator.dart';
import 'package:poker_trainer/poker/models/game_type.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

ProviderContainer _container(UserStatsService service) {
  final c = ProviderContainer(overrides: [
    userStatsServiceProvider.overrideWithValue(service),
  ]);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UserStatsNotifier dispatches achievement events', () {
    test('first hand unlocks first_hand and first_win on a winning hand',
        () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      // Trigger a winning hand replay completion via the public stats API.
      await c.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            event: const HandCompletedEvent(
              heroWon: true,
              heroHandRank: null,
              gameType: GameType.texasHoldem,
              heroWasAllIn: false,
            ),
            now: DateTime(2026, 5, 6),
          );

      final ach = c.read(achievementsProvider);
      expect(ach.progressFor('play_first_hand').isUnlocked, isTrue);
      expect(ach.progressFor('first_win').isUnlocked, isTrue);
      // Daily bonus + base XP + win bonus + achievement rewards.
      final stats = c.read(userStatsProvider);
      // play_first_hand: 25, first_win: 25 → +50 from achievements alone.
      expect(stats.totalXp, greaterThan(50));
      // The achievements unlock list is published.
      final result = c.read(lastDispatchResultProvider);
      expect(
        result.newlyUnlocked.map((a) => a.id),
        containsAll(['play_first_hand', 'first_win']),
      );
    });

    test('lesson completion unlocks lesson_first', () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      await c.read(userStatsProvider.notifier).recordLessonComplete(
            now: DateTime(2026, 5, 6),
          );

      final ach = c.read(achievementsProvider);
      expect(ach.progressFor('lesson_first').isUnlocked, isTrue);
    });

    test('streak milestone unlocks streak_3 after 3 consecutive days',
        () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      final notifier = c.read(userStatsProvider.notifier);
      await notifier.recordHandPlayed(now: DateTime(2026, 5, 6));
      await notifier.recordHandPlayed(now: DateTime(2026, 5, 7));
      await notifier.recordHandPlayed(now: DateTime(2026, 5, 8));

      final ach = c.read(achievementsProvider);
      expect(ach.progressFor('streak_3').isUnlocked, isTrue);
      expect(ach.progressFor('streak_7').isUnlocked, isFalse);
      // Streak achievement value tracks the highest streak seen.
      expect(ach.progressFor('streak_3').value, 3);
    });

    test('resetAll clears achievements and rolls a fresh daily', () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      await c.read(userStatsProvider.notifier).recordLessonComplete(
            now: DateTime(2026, 5, 6),
          );
      expect(c.read(achievementsProvider).unlockedCount, greaterThan(0));

      await c.read(userStatsProvider.notifier).resetAll();
      final ach = c.read(achievementsProvider);
      expect(ach.unlockedCount, 0);
      expect(ach.byId, isEmpty);
      // Daily challenge rolled fresh — has zero progress, not claimed.
      final daily = c.read(dailyChallengeProvider);
      expect(daily.progress, 0);
      expect(daily.claimed, isFalse);
    });

    test('persistence survives container restart', () async {
      final svc = await _freshService();

      final c1 = _container(svc);
      await c1.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            now: DateTime(2026, 5, 6),
          );
      c1.dispose();

      // Fresh container, same service instance: state must come from prefs.
      final c2 = _container(svc);
      addTearDown(c2.dispose);
      final ach = c2.read(achievementsProvider);
      expect(ach.progressFor('first_win').isUnlocked, isTrue);
      expect(ach.progressFor('play_first_hand').isUnlocked, isTrue);
    });

    test('mastery: winning with a flush unlocks win_with_flush', () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      await c.read(userStatsProvider.notifier).recordHandPlayed(
            playerWon: true,
            event: const HandCompletedEvent(
              heroWon: true,
              heroHandRank: HandRank.flush,
              gameType: GameType.texasHoldem,
              heroWasAllIn: false,
            ),
            now: DateTime(2026, 5, 6),
          );
      expect(
        c.read(achievementsProvider).progressFor('win_with_flush').isUnlocked,
        isTrue,
      );
    });

    test('catalog reward XP feeds back into level progression', () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      // 21 hands triggers play_first_hand (25), play_10_hands (50), and
      // first_win (25 if won) — but we lose every hand to keep math simple.
      final notifier = c.read(userStatsProvider.notifier);
      for (var i = 0; i < 11; i++) {
        await notifier.recordHandPlayed(
          now: DateTime(2026, 5, 6, 12, i),
        );
      }
      final stats = c.read(userStatsProvider);
      // Achievement rewards: 25 + 50 = 75 added to base XP+streak bonus.
      // Verify achievements actually unlocked.
      final ach = c.read(achievementsProvider);
      expect(ach.progressFor('play_first_hand').isUnlocked, isTrue);
      expect(ach.progressFor('play_10_hands').isUnlocked, isTrue);
      expect(stats.totalXp, greaterThan(75));
    });
  });

  group('DailyChallengeNotifier', () {
    test('claim is a no-op until the challenge is complete', () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      final daily = c.read(dailyChallengeProvider.notifier);
      final xp = await daily.claim();
      expect(xp, 0);
      expect(c.read(dailyChallengeProvider).claimed, isFalse);
    });

    test('completing the daily and claiming awards XP exactly once',
        () async {
      final svc = await _freshService();
      final c = _container(svc);
      addTearDown(c.dispose);

      // Drive whatever template was rolled for today to completion via
      // synthetic events that satisfy any template's progressFn.
      final tpl = c.read(dailyChallengeProvider).template!;
      final notifier = c.read(dailyChallengeProvider.notifier);

      // Drive progress to target via synthetic events.
      for (var i = 0; i < tpl.target * 3; i++) {
        // Fire all kinds; whatever the template responds to will count.
        await notifier.dispatch(
          const HandCompletedEvent(
            heroWon: true,
            heroHandRank: HandRank.flush,
            gameType: GameType.omaha,
            heroWasAllIn: true,
          ),
        );
        await notifier.dispatch(const LessonCompletedEvent());
      }

      final state = c.read(dailyChallengeProvider);
      expect(state.isComplete, isTrue);

      final xp1 = await notifier.claim();
      expect(xp1, tpl.xpReward);
      expect(c.read(dailyChallengeProvider).claimed, isTrue);

      // Second claim is a no-op.
      final xp2 = await notifier.claim();
      expect(xp2, 0);
    });
  });
}
