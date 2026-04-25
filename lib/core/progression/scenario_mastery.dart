/// Per-scenario mastery tracking for interactive lessons.
///
/// Pure Dart — no Flutter or storage dependencies. Persisted alongside
/// [UserStats] as JSON; fields are short-keyed to keep the on-disk payload
/// compact since this map can grow with the lesson catalog.
library;

/// A single scenario's lifetime mastery record.
class MasteryRecord {
  /// Times the scenario has been completed (any completion, including ones
  /// where undo was used).
  final int completions;

  /// Subset of [completions] where the player never tapped undo on the way
  /// to the river. Drives the higher star tiers.
  final int cleanCompletions;

  /// Highest star tier ever reached for this scenario. Once earned, stars
  /// don't drop even if the player makes mistakes on later replays.
  final int bestStars;

  /// Calendar day the scenario was last completed (UTC midnight key).
  final DateTime? lastPlayedDay;

  const MasteryRecord({
    required this.completions,
    required this.cleanCompletions,
    required this.bestStars,
    this.lastPlayedDay,
  });

  const MasteryRecord.empty()
      : completions = 0,
        cleanCompletions = 0,
        bestStars = 0,
        lastPlayedDay = null;

  /// Star tier (0..3) implied by raw completion counts.
  ///
  /// - 1 star: at least one completion.
  /// - 2 stars: at least one clean completion (no undo used).
  /// - 3 stars: three or more clean completions — true mastery.
  static int starsFor({
    required int completions,
    required int cleanCompletions,
  }) {
    if (completions <= 0) return 0;
    if (cleanCompletions <= 0) return 1;
    if (cleanCompletions < 3) return 2;
    return 3;
  }

  /// Apply a fresh completion to produce a new record.
  MasteryRecord recordCompletion({
    required bool clean,
    required DateTime now,
  }) {
    final newCompletions = completions + 1;
    final newClean = clean ? cleanCompletions + 1 : cleanCompletions;
    final newStars = starsFor(
      completions: newCompletions,
      cleanCompletions: newClean,
    );
    return MasteryRecord(
      completions: newCompletions,
      cleanCompletions: newClean,
      bestStars: newStars > bestStars ? newStars : bestStars,
      lastPlayedDay: now,
    );
  }

  Map<String, dynamic> toJson() => {
        'c': completions,
        'k': cleanCompletions,
        's': bestStars,
        if (lastPlayedDay != null) 'd': lastPlayedDay!.toIso8601String(),
      };

  static MasteryRecord fromJson(Map<String, dynamic> map) {
    return MasteryRecord(
      completions: (map['c'] as num?)?.toInt() ?? 0,
      cleanCompletions: (map['k'] as num?)?.toInt() ?? 0,
      bestStars: (map['s'] as num?)?.toInt() ?? 0,
      lastPlayedDay: map['d'] is String
          ? DateTime.tryParse(map['d'] as String)
          : null,
    );
  }
}

/// Build a stable scenario key from a lesson id + scenario index.
String scenarioKeyFor(String lessonId, int scenarioIndex) =>
    '$lessonId/$scenarioIndex';
