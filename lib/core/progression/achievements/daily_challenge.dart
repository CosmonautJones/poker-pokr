import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../poker/engine/hand_evaluator.dart';
import '../../../poker/models/game_type.dart';
import '../user_stats.dart';
import 'achievement_event.dart';

/// Static template for one daily challenge.
@immutable
class DailyChallengeTemplate {
  /// Stable identifier; used to reference the template after a roll.
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int xpReward;
  final int Function(AchievementEvent event, int currentValue) progressFn;

  const DailyChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.xpReward,
    required this.progressFn,
  });
}

/// All possible daily challenges. The active one is picked deterministically
/// per-day via [DailyChallenge.rollFor].
final List<DailyChallengeTemplate> dailyChallengeTemplates = [
  DailyChallengeTemplate(
    id: 'play_3',
    title: 'Stay in the Game',
    description: 'Play 3 hands today.',
    icon: Icons.style_rounded,
    target: 3,
    xpReward: 50,
    progressFn: (e, v) => e is HandCompletedEvent ? v + 1 : v,
  ),
  DailyChallengeTemplate(
    id: 'win_1',
    title: 'Bring Home a Pot',
    description: 'Win a hand today.',
    icon: Icons.emoji_events_rounded,
    target: 1,
    xpReward: 75,
    progressFn: (e, v) =>
        (e is HandCompletedEvent && e.heroWon) ? v + 1 : v,
  ),
  DailyChallengeTemplate(
    id: 'lesson_1',
    title: 'Sharpen Up',
    description: 'Complete a lesson today.',
    icon: Icons.school_rounded,
    target: 1,
    xpReward: 75,
    progressFn: (e, v) => e is LessonCompletedEvent ? v + 1 : v,
  ),
  DailyChallengeTemplate(
    id: 'pair_or_better',
    title: 'Hit a Hand',
    description: 'Win 2 hands at showdown today.',
    icon: Icons.casino_rounded,
    target: 2,
    xpReward: 75,
    progressFn: (e, v) {
      if (e is HandCompletedEvent && e.heroWon && e.heroHandRank != null) {
        return v + 1;
      }
      return v;
    },
  ),
  DailyChallengeTemplate(
    id: 'big_hand',
    title: 'Land a Monster',
    description: 'Win a hand with a flush or better today.',
    icon: Icons.water_drop_rounded,
    target: 1,
    xpReward: 100,
    progressFn: (e, v) {
      if (e is HandCompletedEvent &&
          e.heroWon &&
          e.heroHandRank != null &&
          e.heroHandRank!.index >= HandRank.flush.index) {
        return v + 1;
      }
      return v;
    },
  ),
  DailyChallengeTemplate(
    id: 'omaha_play',
    title: 'Mix It Up',
    description: 'Play an Omaha hand today.',
    icon: Icons.swap_horiz_rounded,
    target: 1,
    xpReward: 75,
    progressFn: (e, v) =>
        (e is HandCompletedEvent && e.gameType == GameType.omaha)
            ? v + 1
            : v,
  ),
  DailyChallengeTemplate(
    id: 'play_5',
    title: 'Volume Day',
    description: 'Play 5 hands today.',
    icon: Icons.local_fire_department_rounded,
    target: 5,
    xpReward: 75,
    progressFn: (e, v) => e is HandCompletedEvent ? v + 1 : v,
  ),
];

DailyChallengeTemplate? dailyTemplateById(String id) {
  for (final t in dailyChallengeTemplates) {
    if (t.id == id) return t;
  }
  return null;
}

/// Active daily challenge — template id + day key + running progress and
/// claim state. Persisted as JSON.
@immutable
class DailyChallenge {
  static const storageKey = 'daily_challenge_v1';

  /// yyyy-mm-dd UTC normalized day. If today != [day], the challenge has
  /// expired and a new one should be rolled.
  final DateTime day;
  final String templateId;
  final int progress;
  final bool claimed;

  const DailyChallenge({
    required this.day,
    required this.templateId,
    required this.progress,
    required this.claimed,
  });

  bool isForToday(DateTime now) =>
      Progression.dayKey(day) == Progression.dayKey(now);

  DailyChallengeTemplate? get template => dailyTemplateById(templateId);

  bool get isComplete {
    final t = template;
    return t != null && progress >= t.target;
  }

  double get progressFraction {
    final t = template;
    if (t == null || t.target == 0) return 0;
    return (progress / t.target).clamp(0.0, 1.0);
  }

  DailyChallenge copyWith({int? progress, bool? claimed}) =>
      DailyChallenge(
        day: day,
        templateId: templateId,
        progress: progress ?? this.progress,
        claimed: claimed ?? this.claimed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyChallenge &&
          other.day == day &&
          other.templateId == templateId &&
          other.progress == progress &&
          other.claimed == claimed);

  @override
  int get hashCode => Object.hash(day, templateId, progress, claimed);

  /// Deterministically pick a template for [now].
  ///
  /// Uses the local-zone day-of-year so that everyone running the app on the
  /// same calendar day sees the same challenge, but the rotation cycles across
  /// days. Skipping a day still rotates so users don't see the same challenge
  /// after a break.
  static DailyChallenge rollFor(DateTime now) {
    final dayKey = Progression.dayKey(now);
    final ordinal = _dayOrdinal(dayKey);
    final template =
        dailyChallengeTemplates[ordinal % dailyChallengeTemplates.length];
    return DailyChallenge(
      day: dayKey,
      templateId: template.id,
      progress: 0,
      claimed: false,
    );
  }

  /// Return a fresh roll if [existing] is null, missing template, or stale;
  /// otherwise return [existing] unchanged.
  static DailyChallenge ensureForToday(
    DailyChallenge? existing,
    DateTime now,
  ) {
    if (existing == null ||
        !existing.isForToday(now) ||
        existing.template == null) {
      return rollFor(now);
    }
    return existing;
  }

  Map<String, dynamic> toJson() => {
        'day': day.toIso8601String(),
        'tpl': templateId,
        'p': progress,
        'c': claimed,
      };

  String encode() => jsonEncode(toJson());

  static DailyChallenge? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final dayStr = map['day'];
      final tpl = map['tpl'];
      if (dayStr is! String || tpl is! String) return null;
      final day = DateTime.tryParse(dayStr);
      if (day == null) return null;
      return DailyChallenge(
        day: day,
        templateId: tpl,
        progress: (map['p'] as num?)?.toInt() ?? 0,
        claimed: map['c'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Days since 1970-01-01 in the local zone. Stable per calendar day.
  static int _dayOrdinal(DateTime dayKey) {
    return dayKey.difference(DateTime(1970, 1, 1)).inDays;
  }
}
