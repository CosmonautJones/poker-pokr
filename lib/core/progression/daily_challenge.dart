/// Pure-Dart deterministic daily-challenge picker.
///
/// Picks one lesson scenario per local calendar day from a flattened list
/// of `(lessonId, scenarioIndex)` pairs. The mapping is stable across app
/// launches as long as the catalog order is unchanged. Uses local-time day
/// boundaries so the challenge rolls over at the user's midnight, matching
/// the streak rollover in [Progression.dayKey].
library;

import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';

import 'user_stats.dart';

/// A single daily-challenge selection.
class DailyChallengeRef {
  final String lessonId;
  final int scenarioIndex;
  final String lessonTitle;
  final String scenarioTitle;
  final String scenarioDescription;

  const DailyChallengeRef({
    required this.lessonId,
    required this.scenarioIndex,
    required this.lessonTitle,
    required this.scenarioTitle,
    required this.scenarioDescription,
  });
}

/// Flattens [lessonsCatalog] into a stable `(lessonId, scenarioIndex)` list.
/// Order: catalog order, then scenario index inside each lesson.
List<DailyChallengeRef> buildDailyPool() {
  final pool = <DailyChallengeRef>[];
  for (final lesson in lessonsCatalog) {
    for (var i = 0; i < lesson.scenarios.length; i++) {
      final s = lesson.scenarios[i];
      pool.add(DailyChallengeRef(
        lessonId: lesson.id,
        scenarioIndex: i,
        lessonTitle: lesson.title,
        scenarioTitle: s.title,
        scenarioDescription: s.description,
      ));
    }
  }
  return pool;
}

/// Picks today's challenge for [now] using a stable epoch-day index.
///
/// Returns null only if the catalog is empty (defensive — currently there
/// are scenarios in the seed catalog).
DailyChallengeRef? challengeFor(DateTime now, {List<DailyChallengeRef>? pool}) {
  final p = pool ?? buildDailyPool();
  if (p.isEmpty) return null;
  final dayIndex = _epochDay(now);
  // Modulo on signed indices behaves correctly because epoch days are
  // strictly positive for any realistic clock.
  return p[dayIndex % p.length];
}

/// Calendar-day epoch index in the local zone. We avoid UTC because the
/// streak system also uses local midnights — keeping both consistent is
/// what makes "play once a day to keep your streak" feel natural.
int _epochDay(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  return local.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
}

/// True if [stats] indicates the daily challenge for [now] is already done.
/// Thin wrapper over [UserStats.dailyChallengeDoneOn] for symmetry with the
/// other helpers in this file.
bool isDailyChallengeDone(UserStats stats, DateTime now) =>
    stats.dailyChallengeDoneOn(now);
