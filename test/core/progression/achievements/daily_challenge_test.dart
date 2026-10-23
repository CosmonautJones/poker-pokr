import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements/achievement_event.dart';
import 'package:poker_trainer/core/progression/achievements/daily_challenge.dart';
import 'package:poker_trainer/poker/engine/hand_evaluator.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

void main() {
  group('DailyChallenge.rollFor', () {
    test('two calls on the same calendar day pick the same template', () {
      final a = DailyChallenge.rollFor(DateTime(2026, 5, 6, 9, 0));
      final b = DailyChallenge.rollFor(DateTime(2026, 5, 6, 23, 59));
      expect(a.templateId, b.templateId);
      expect(a.day, b.day);
    });

    test('different calendar days roll different templates eventually', () {
      // Across the catalog length, at least one neighboring day must rotate.
      final ids = <String>{};
      for (var i = 0; i < dailyChallengeTemplates.length + 2; i++) {
        ids.add(DailyChallenge.rollFor(DateTime(2026, 5, 6 + i)).templateId);
      }
      expect(ids.length, dailyChallengeTemplates.length);
    });

    test('rolled challenge starts at zero progress, not claimed', () {
      final c = DailyChallenge.rollFor(DateTime(2026, 5, 6));
      expect(c.progress, 0);
      expect(c.claimed, isFalse);
      expect(c.isComplete, isFalse);
      expect(c.template, isNotNull);
    });
  });

  group('DailyChallenge.ensureForToday', () {
    test('returns existing when same calendar day', () {
      final today = DateTime(2026, 5, 6, 8);
      final existing = DailyChallenge.rollFor(today);
      final ensured = DailyChallenge.ensureForToday(
        existing,
        DateTime(2026, 5, 6, 22),
      );
      expect(ensured, same(existing));
    });

    test('rolls fresh when day rolls over', () {
      final yesterday = DailyChallenge.rollFor(DateTime(2026, 5, 6));
      final ensured = DailyChallenge.ensureForToday(
        yesterday,
        DateTime(2026, 5, 7),
      );
      expect(ensured, isNot(same(yesterday)));
      expect(ensured.day, isNot(yesterday.day));
      expect(ensured.progress, 0);
    });

    test('rolls fresh when null', () {
      final ensured =
          DailyChallenge.ensureForToday(null, DateTime(2026, 5, 6));
      expect(ensured.template, isNotNull);
      expect(ensured.progress, 0);
    });
  });

  group('DailyChallenge persistence', () {
    test('encode/decode round-trip preserves all fields', () {
      final c = DailyChallenge(
        day: DateTime(2026, 5, 6),
        templateId: 'play_3',
        progress: 2,
        claimed: false,
      );
      final restored = DailyChallenge.tryDecode(c.encode());
      expect(restored, equals(c));
    });

    test('decode of garbage returns null', () {
      expect(DailyChallenge.tryDecode(null), isNull);
      expect(DailyChallenge.tryDecode(''), isNull);
      expect(DailyChallenge.tryDecode('{}'), isNull);
      expect(DailyChallenge.tryDecode('{"day":"oops"}'), isNull);
    });
  });

  group('DailyChallenge progress functions', () {
    DailyChallengeTemplate _byId(String id) =>
        dailyTemplateById(id) ?? (throw StateError('no template $id'));

    test('play_3 increments on any HandCompletedEvent', () {
      final tpl = _byId('play_3');
      const event = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      expect(tpl.progressFn(event, 0), 1);
      expect(tpl.progressFn(event, 2), 3);
      expect(tpl.progressFn(const LessonCompletedEvent(), 1), 1);
    });

    test('win_1 only fires when heroWon is true', () {
      final tpl = _byId('win_1');
      const lose = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      const win = HandCompletedEvent(
        heroWon: true,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      expect(tpl.progressFn(lose, 0), 0);
      expect(tpl.progressFn(win, 0), 1);
    });

    test('big_hand requires flush or better', () {
      final tpl = _byId('big_hand');
      HandCompletedEvent withRank(HandRank? r) => HandCompletedEvent(
            heroWon: true,
            heroHandRank: r,
            gameType: GameType.texasHoldem,
            heroWasAllIn: false,
          );
      expect(tpl.progressFn(withRank(HandRank.pair), 0), 0);
      expect(tpl.progressFn(withRank(HandRank.straight), 0), 0);
      expect(tpl.progressFn(withRank(HandRank.flush), 0), 1);
      expect(tpl.progressFn(withRank(HandRank.fullHouse), 0), 1);
      expect(tpl.progressFn(withRank(HandRank.straightFlush), 0), 1);
      expect(tpl.progressFn(withRank(null), 0), 0);
    });

    test('omaha_play requires Omaha game type', () {
      final tpl = _byId('omaha_play');
      const holdem = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      const omaha = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.omaha,
        heroWasAllIn: false,
      );
      expect(tpl.progressFn(holdem, 0), 0);
      expect(tpl.progressFn(omaha, 0), 1);
    });

    test('lesson_1 fires on LessonCompletedEvent', () {
      final tpl = _byId('lesson_1');
      expect(
        tpl.progressFn(const LessonCompletedEvent(), 0),
        1,
      );
      expect(
        tpl.progressFn(
          const HandCompletedEvent(
            heroWon: true,
            heroHandRank: null,
            gameType: GameType.texasHoldem,
            heroWasAllIn: false,
          ),
          0,
        ),
        0,
      );
    });
  });
}
