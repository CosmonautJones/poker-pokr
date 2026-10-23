/// Events that can advance achievement and daily-challenge progress.
///
/// Pure value types — no Flutter, no IO. Dispatched by [UserStatsNotifier]
/// after a hand or lesson completes, or after a derived stat (level / streak)
/// crosses a new value.
library;

import '../../../poker/engine/hand_evaluator.dart';
import '../../../poker/models/game_type.dart';

sealed class AchievementEvent {
  const AchievementEvent();
}

/// Fired once per completed hand. [heroHandRank] is null when the hand was
/// won by fold (no showdown) or when the hero folded.
class HandCompletedEvent extends AchievementEvent {
  final bool heroWon;
  final HandRank? heroHandRank;
  final GameType gameType;

  /// True when the hero's stack was zero at the end of the hand or the hero
  /// shoved at any point during the hand.
  final bool heroWasAllIn;

  const HandCompletedEvent({
    required this.heroWon,
    required this.heroHandRank,
    required this.gameType,
    required this.heroWasAllIn,
  });
}

/// Fired once per completed lesson scenario.
class LessonCompletedEvent extends AchievementEvent {
  const LessonCompletedEvent();
}

/// Fired after [UserStatsNotifier] settles a play event whenever the streak
/// counter took a step up (i.e. the user opened a new day of activity).
class StreakAdvancedEvent extends AchievementEvent {
  final int streakDays;
  const StreakAdvancedEvent(this.streakDays);
}

/// Fired after [UserStatsNotifier] applies XP whenever the player's level
/// increased compared to the previous snapshot.
class LevelReachedEvent extends AchievementEvent {
  final int level;
  const LevelReachedEvent(this.level);
}
