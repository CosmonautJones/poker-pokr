import 'dart:convert';

/// Kinds of progress events that move a daily challenge forward.
enum ChallengeKind { handsPlayed, handsWon, lessonsCompleted }

/// Static definition of a challenge: what to do, how much, and the reward.
class ChallengeTemplate {
  /// Stable id, persisted into [DailyChallenge.templateId].
  final String id;
  final ChallengeKind kind;
  final int target;
  final String title;
  final int xpReward;

  const ChallengeTemplate({
    required this.id,
    required this.kind,
    required this.target,
    required this.title,
    required this.xpReward,
  });
}

/// Curated list of templates. The selection algorithm picks one per local
/// calendar day; rewards scale with effort.
const kChallengeTemplates = <ChallengeTemplate>[
  ChallengeTemplate(
    id: 'play_3_hands',
    kind: ChallengeKind.handsPlayed,
    target: 3,
    title: 'Play 3 hands',
    xpReward: 25,
  ),
  ChallengeTemplate(
    id: 'play_5_hands',
    kind: ChallengeKind.handsPlayed,
    target: 5,
    title: 'Play 5 hands',
    xpReward: 35,
  ),
  ChallengeTemplate(
    id: 'play_10_hands',
    kind: ChallengeKind.handsPlayed,
    target: 10,
    title: 'Play 10 hands',
    xpReward: 60,
  ),
  ChallengeTemplate(
    id: 'win_1_showdown',
    kind: ChallengeKind.handsWon,
    target: 1,
    title: 'Win 1 hand at showdown',
    xpReward: 30,
  ),
  ChallengeTemplate(
    id: 'win_2_showdowns',
    kind: ChallengeKind.handsWon,
    target: 2,
    title: 'Win 2 hands at showdown',
    xpReward: 50,
  ),
  ChallengeTemplate(
    id: 'win_3_showdowns',
    kind: ChallengeKind.handsWon,
    target: 3,
    title: 'Win 3 hands at showdown',
    xpReward: 75,
  ),
  ChallengeTemplate(
    id: 'complete_1_lesson',
    kind: ChallengeKind.lessonsCompleted,
    target: 1,
    title: 'Complete a lesson',
    xpReward: 30,
  ),
  ChallengeTemplate(
    id: 'complete_2_lessons',
    kind: ChallengeKind.lessonsCompleted,
    target: 2,
    title: 'Complete 2 lessons',
    xpReward: 60,
  ),
  ChallengeTemplate(
    id: 'play_4_hands',
    kind: ChallengeKind.handsPlayed,
    target: 4,
    title: 'Play 4 hands',
    xpReward: 30,
  ),
  ChallengeTemplate(
    id: 'play_7_hands',
    kind: ChallengeKind.handsPlayed,
    target: 7,
    title: 'Play 7 hands',
    xpReward: 45,
  ),
  ChallengeTemplate(
    id: 'win_and_play',
    kind: ChallengeKind.handsPlayed,
    target: 6,
    title: 'Play 6 hands today',
    xpReward: 40,
  ),
  ChallengeTemplate(
    id: 'lesson_marathon',
    kind: ChallengeKind.lessonsCompleted,
    target: 3,
    title: 'Complete 3 lessons',
    xpReward: 90,
  ),
];

/// Per-day persisted challenge state.
class DailyChallenge {
  /// Local calendar day this challenge belongs to, formatted yyyy-MM-dd.
  final String dayKey;

  /// Id of the chosen template (look up via [findTemplate]).
  final String templateId;

  /// Current count toward [ChallengeTemplate.target].
  final int progress;

  /// True once [progress] reached the target.
  final bool completed;

  /// True once the XP reward has been awarded to the user.
  final bool xpClaimed;

  const DailyChallenge({
    required this.dayKey,
    required this.templateId,
    required this.progress,
    required this.completed,
    required this.xpClaimed,
  });

  /// Fresh challenge for [dayKey] using the given [template].
  factory DailyChallenge.fresh({
    required String dayKey,
    required ChallengeTemplate template,
  }) =>
      DailyChallenge(
        dayKey: dayKey,
        templateId: template.id,
        progress: 0,
        completed: false,
        xpClaimed: false,
      );

  DailyChallenge copyWith({
    String? dayKey,
    String? templateId,
    int? progress,
    bool? completed,
    bool? xpClaimed,
  }) =>
      DailyChallenge(
        dayKey: dayKey ?? this.dayKey,
        templateId: templateId ?? this.templateId,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
        xpClaimed: xpClaimed ?? this.xpClaimed,
      );

  Map<String, dynamic> toJson() => {
        'dayKey': dayKey,
        'templateId': templateId,
        'progress': progress,
        'completed': completed,
        'xpClaimed': xpClaimed,
      };

  String encode() => jsonEncode(toJson());

  static DailyChallenge? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dayKey = map['dayKey'] as String?;
      final templateId = map['templateId'] as String?;
      if (dayKey == null || templateId == null) return null;
      return DailyChallenge(
        dayKey: dayKey,
        templateId: templateId,
        progress: (map['progress'] as num?)?.toInt() ?? 0,
        completed: map['completed'] as bool? ?? false,
        xpClaimed: map['xpClaimed'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Pure helpers for day-key derivation, template selection, and progression.
abstract final class ChallengeAlgorithm {
  /// Local calendar-day string used as the rollover key. Use the local zone
  /// because challenges should rotate when the player perceives a new day.
  static String dayKey(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Day-of-year for [date] (1-366).
  static int _dayOfYear(DateTime date) {
    final start = DateTime(date.year);
    return date.difference(start).inDays + 1;
  }

  /// Deterministic template index for [now]. Same day always picks the same
  /// challenge across restarts.
  static ChallengeTemplate templateForDay(DateTime now) {
    final seed = _dayOfYear(now) * 31 + now.year;
    final idx = seed.abs() % kChallengeTemplates.length;
    return kChallengeTemplates[idx];
  }

  /// Returns null when no template matches the stored id (shouldn't happen
  /// outside of mid-rollout shape changes; callers should fall back to
  /// minting a fresh challenge).
  static ChallengeTemplate? findTemplate(String templateId) {
    for (final t in kChallengeTemplates) {
      if (t.id == templateId) return t;
    }
    return null;
  }

  /// Apply a [kind] event to [challenge] using its [template]. Returns the
  /// updated challenge and the XP reward to award (>0 only when the event
  /// flipped the challenge from incomplete to complete and [completionXp]
  /// hadn't been claimed yet).
  static ChallengeProgressResult applyEvent({
    required DailyChallenge challenge,
    required ChallengeTemplate template,
    required ChallengeKind kind,
  }) {
    if (challenge.completed) {
      return ChallengeProgressResult(
        next: challenge,
        completionXp: 0,
      );
    }
    if (kind != template.kind) {
      return ChallengeProgressResult(
        next: challenge,
        completionXp: 0,
      );
    }
    final nextProgress = challenge.progress + 1;
    final nowComplete = nextProgress >= template.target;
    return ChallengeProgressResult(
      next: challenge.copyWith(
        progress: nextProgress,
        completed: nowComplete,
        xpClaimed: nowComplete,
      ),
      completionXp: nowComplete ? template.xpReward : 0,
    );
  }
}

class ChallengeProgressResult {
  final DailyChallenge next;
  final int completionXp;

  const ChallengeProgressResult({
    required this.next,
    required this.completionXp,
  });
}
