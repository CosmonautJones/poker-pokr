import 'package:flutter_test/flutter_test.dart';
import 'package:poker_trainer/core/progression/achievements/achievement.dart';
import 'package:poker_trainer/core/progression/achievements/achievement_event.dart';
import 'package:poker_trainer/core/progression/achievements/achievements_catalog.dart';
import 'package:poker_trainer/poker/engine/hand_evaluator.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

void main() {
  group('Achievement helpers', () {
    test('counter increments only when match returns true', () {
      final fn = Achievement.counter(
        (e) => e is HandCompletedEvent && e.heroWon,
      );
      const win = HandCompletedEvent(
        heroWon: true,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      const lose = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      expect(fn(win, 0), 1);
      expect(fn(win, 5), 6);
      expect(fn(lose, 5), 5);
      expect(fn(const LessonCompletedEvent(), 5), 5);
    });

    test('maxOf only goes up; unmatched events leave value unchanged', () {
      final fn = Achievement.maxOf(
        (e) => e is StreakAdvancedEvent ? e.streakDays : null,
      );
      expect(fn(const StreakAdvancedEvent(3), 0), 3);
      expect(fn(const StreakAdvancedEvent(2), 5), 5);
      expect(fn(const StreakAdvancedEvent(7), 5), 7);
      expect(fn(const LessonCompletedEvent(), 7), 7);
    });
  });

  group('Catalog content', () {
    test('catalog has at least 12 achievements covering every category', () {
      expect(achievementsCatalog.length, greaterThanOrEqualTo(12));
      final cats = achievementsCatalog.map((a) => a.category).toSet();
      // Every category from the enum should be represented.
      for (final c in AchievementCategory.values) {
        expect(cats, contains(c), reason: 'missing category $c');
      }
    });

    test('all ids are unique', () {
      final ids = achievementsCatalog.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('every achievement has positive threshold and xpReward', () {
      for (final a in achievementsCatalog) {
        expect(a.threshold, greaterThan(0), reason: a.id);
        expect(a.xpReward, greaterThan(0), reason: a.id);
      }
    });

    test('mastery achievements only fire on matching HandRank', () {
      final flush = achievementById('win_with_flush')!;
      HandCompletedEvent ev(HandRank? r) => HandCompletedEvent(
            heroWon: true,
            heroHandRank: r,
            gameType: GameType.texasHoldem,
            heroWasAllIn: false,
          );
      expect(flush.progressFn(ev(HandRank.straight), 0), 0);
      expect(flush.progressFn(ev(HandRank.flush), 0), 1);
      expect(flush.progressFn(ev(HandRank.fullHouse), 0), 0);
      expect(flush.progressFn(ev(null), 0), 0);
      // Losing with a flush doesn't count.
      expect(
        flush.progressFn(
          const HandCompletedEvent(
            heroWon: false,
            heroHandRank: HandRank.flush,
            gameType: GameType.texasHoldem,
            heroWasAllIn: false,
          ),
          0,
        ),
        0,
      );
    });

    test('streak achievements track the highest streakDays seen', () {
      final s7 = achievementById('streak_7')!;
      expect(s7.progressFn(const StreakAdvancedEvent(3), 0), 3);
      expect(s7.progressFn(const StreakAdvancedEvent(2), 3), 3);
      expect(s7.progressFn(const StreakAdvancedEvent(7), 3), 7);
    });

    test('level achievements track the highest level seen', () {
      final l5 = achievementById('level_5')!;
      expect(l5.progressFn(const LevelReachedEvent(2), 0), 2);
      expect(l5.progressFn(const LevelReachedEvent(5), 2), 5);
      expect(l5.progressFn(const LevelReachedEvent(3), 5), 5);
    });

    test('all_in_win requires heroWon AND heroWasAllIn', () {
      final a = achievementById('all_in_win')!;
      const wonClean = HandCompletedEvent(
        heroWon: true,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: false,
      );
      const wonAllIn = HandCompletedEvent(
        heroWon: true,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: true,
      );
      const lostAllIn = HandCompletedEvent(
        heroWon: false,
        heroHandRank: null,
        gameType: GameType.texasHoldem,
        heroWasAllIn: true,
      );
      expect(a.progressFn(wonClean, 0), 0);
      expect(a.progressFn(lostAllIn, 0), 0);
      expect(a.progressFn(wonAllIn, 0), 1);
    });
  });
}
