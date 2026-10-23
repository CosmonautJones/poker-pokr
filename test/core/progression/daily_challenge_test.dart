import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/daily_challenge.dart';
import 'package:poker_trainer/core/progression/daily_challenge_provider.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<UserStatsService> _freshService() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return UserStatsService(prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChallengeAlgorithm.dayKey', () {
    test('formats yyyy-MM-dd, zero-padded', () {
      expect(
        ChallengeAlgorithm.dayKey(DateTime(2026, 1, 5)),
        '2026-01-05',
      );
      expect(
        ChallengeAlgorithm.dayKey(DateTime(2026, 12, 31)),
        '2026-12-31',
      );
    });
  });

  group('ChallengeAlgorithm.templateForDay', () {
    test('is deterministic for the same date', () {
      final a = ChallengeAlgorithm.templateForDay(DateTime(2026, 5, 7));
      final b = ChallengeAlgorithm.templateForDay(DateTime(2026, 5, 7));
      expect(a.id, b.id);
    });

    test('returns a valid catalog entry', () {
      final t = ChallengeAlgorithm.templateForDay(DateTime(2026, 5, 7));
      expect(kChallengeTemplates.any((c) => c.id == t.id), isTrue);
    });
  });

  group('ChallengeAlgorithm.applyEvent', () {
    final tpl = const ChallengeTemplate(
      id: 'test_play_2',
      kind: ChallengeKind.handsPlayed,
      target: 2,
      title: 'Play 2 hands',
      xpReward: 25,
    );

    test('matching kind increments progress', () {
      final c = DailyChallenge.fresh(dayKey: '2026-01-01', template: tpl);
      final r = ChallengeAlgorithm.applyEvent(
        challenge: c,
        template: tpl,
        kind: ChallengeKind.handsPlayed,
      );
      expect(r.next.progress, 1);
      expect(r.next.completed, isFalse);
      expect(r.completionXp, 0);
    });

    test('non-matching kind is a no-op', () {
      final c = DailyChallenge.fresh(dayKey: '2026-01-01', template: tpl);
      final r = ChallengeAlgorithm.applyEvent(
        challenge: c,
        template: tpl,
        kind: ChallengeKind.lessonsCompleted,
      );
      expect(r.next.progress, 0);
      expect(r.completionXp, 0);
      expect(identical(r.next, c), isTrue);
    });

    test('completion awards xpReward exactly once', () {
      final c = DailyChallenge.fresh(dayKey: '2026-01-01', template: tpl);
      final r1 = ChallengeAlgorithm.applyEvent(
        challenge: c,
        template: tpl,
        kind: ChallengeKind.handsPlayed,
      );
      final r2 = ChallengeAlgorithm.applyEvent(
        challenge: r1.next,
        template: tpl,
        kind: ChallengeKind.handsPlayed,
      );
      expect(r2.next.completed, isTrue);
      expect(r2.completionXp, tpl.xpReward);

      // Subsequent matching events: completed sticks, no extra XP.
      final r3 = ChallengeAlgorithm.applyEvent(
        challenge: r2.next,
        template: tpl,
        kind: ChallengeKind.handsPlayed,
      );
      expect(r3.completionXp, 0);
      expect(r3.next.completed, isTrue);
    });
  });

  group('DailyChallenge JSON', () {
    test('round-trips through encode / tryDecode', () {
      const c = DailyChallenge(
        dayKey: '2026-05-07',
        templateId: 'play_3_hands',
        progress: 2,
        completed: false,
        xpClaimed: false,
      );
      final decoded = DailyChallenge.tryDecode(c.encode());
      expect(decoded, isNotNull);
      expect(decoded!.dayKey, c.dayKey);
      expect(decoded.templateId, c.templateId);
      expect(decoded.progress, c.progress);
      expect(decoded.completed, c.completed);
    });

    test('tryDecode returns null on garbage input', () {
      expect(DailyChallenge.tryDecode('not json'), isNull);
      expect(DailyChallenge.tryDecode(''), isNull);
      expect(DailyChallenge.tryDecode(null), isNull);
    });
  });

  group('DailyChallengeNotifier', () {
    test('mints a fresh challenge for today on first build', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final today = ChallengeAlgorithm.dayKey(DateTime.now());
      final challenge = container.read(dailyChallengeProvider);
      expect(challenge.dayKey, today);
      expect(challenge.progress, 0);
      expect(challenge.completed, isFalse);
      // Persisted.
      expect(service.loadChallenge(), isNotNull);
    });

    test('recordEvent of matching kind ticks progress', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final tpl = notifier.template;
      // Pick the kind that matches today's challenge so the test is
      // deterministic across days.
      await notifier.recordEvent(tpl.kind);

      final state = container.read(dailyChallengeProvider);
      expect(state.progress, 1);
    });

    test('completion awards XP into userStatsProvider exactly once',
        () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final tpl = notifier.template;
      // Drive to completion.
      for (int i = 0; i < tpl.target + 1; i++) {
        await notifier.recordEvent(tpl.kind);
      }
      final stats = container.read(userStatsProvider);
      expect(stats.totalXp, tpl.xpReward);
      final state = container.read(dailyChallengeProvider);
      expect(state.completed, isTrue);
    });

    test('resetAll wipes persisted state and re-mints', () async {
      final service = await _freshService();
      final container = ProviderContainer(overrides: [
        userStatsServiceProvider.overrideWithValue(service),
      ]);
      addTearDown(container.dispose);

      final notifier = container.read(dailyChallengeProvider.notifier);
      final tpl = notifier.template;
      await notifier.recordEvent(tpl.kind);
      expect(container.read(dailyChallengeProvider).progress, 1);

      await notifier.resetAll();
      final fresh = container.read(dailyChallengeProvider);
      expect(fresh.progress, 0);
      expect(fresh.completed, isFalse);
    });
  });
}
