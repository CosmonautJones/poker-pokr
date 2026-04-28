import 'dart:convert';

import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Compile-time definition of a single daily-challenge template.
class DailyChallengeDefinition {
  final String id;
  final String title;
  final String description;
  final int target;
  final int iconCodepoint;
  final int xpReward;

  const DailyChallengeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.target,
    required this.iconCodepoint,
    required this.xpReward,
  });

  IconData get icon => IconData(iconCodepoint, fontFamily: 'MaterialIcons');
}

/// Per-day challenge state. [date] uses [Progression.dayKey] in local time.
class DailyChallenge {
  final String definitionId;
  final int progress;
  final bool completed;
  final DateTime date;

  const DailyChallenge({
    required this.definitionId,
    required this.progress,
    required this.completed,
    required this.date,
  });

  DailyChallenge copyWith({
    int? progress,
    bool? completed,
  }) =>
      DailyChallenge(
        definitionId: definitionId,
        progress: progress ?? this.progress,
        completed: completed ?? this.completed,
        date: date,
      );

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'progress': progress,
        'completed': completed,
        'date': _yyyyMmDd(date),
      };

  static DailyChallenge? tryFromJson(Map<String, dynamic> map) {
    final id = map['definitionId'];
    if (id is! String) return null;
    final dateRaw = map['date'];
    final date =
        dateRaw is String ? _parseYyyyMmDd(dateRaw) : null;
    if (date == null) return null;
    return DailyChallenge(
      definitionId: id,
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      completed: map['completed'] == true,
      date: date,
    );
  }
}

/// Catalog of challenge templates and the deterministic daily picker.
abstract final class DailyChallenges {
  static const storageKey = 'daily_challenges_v1';

  /// Number of challenges surfaced per day.
  static const dailyCount = 3;

  static const all = <DailyChallengeDefinition>[
    DailyChallengeDefinition(
      id: 'play_3',
      title: 'Play 3 hands',
      description: 'Finish three hands today.',
      target: 3,
      iconCodepoint: 0xe5d5, // Icons.casino
      xpReward: 30,
    ),
    DailyChallengeDefinition(
      id: 'play_5',
      title: 'Play 5 hands',
      description: 'Finish five hands today.',
      target: 5,
      iconCodepoint: 0xe5d5, // Icons.casino
      xpReward: 50,
    ),
    DailyChallengeDefinition(
      id: 'lesson_1',
      title: 'Complete 1 lesson',
      description: 'Complete one lesson scenario.',
      target: 1,
      iconCodepoint: 0xe80c, // Icons.school
      xpReward: 50,
    ),
    DailyChallengeDefinition(
      id: 'showdown_1',
      title: 'Reach 1 showdown',
      description: 'Take a hand to showdown.',
      target: 1,
      iconCodepoint: 0xea1b, // Icons.emoji_events
      xpReward: 20,
    ),
    DailyChallengeDefinition(
      id: 'win_1',
      title: 'Win 1 hand at showdown',
      description: 'Take down a pot at showdown.',
      target: 1,
      iconCodepoint: 0xea65, // Icons.workspace_premium
      xpReward: 40,
    ),
    DailyChallengeDefinition(
      id: 'study_outs',
      title: 'View outs panel 3 times',
      description: 'Tap into the outs trainer three times.',
      target: 3,
      iconCodepoint: 0xe865, // Icons.menu_book
      xpReward: 20,
    ),
    DailyChallengeDefinition(
      id: 'session_log',
      title: 'Log a session in Bookkeeper',
      description: 'Add one session to your bookkeeper.',
      target: 1,
      iconCodepoint: 0xe06f, // Icons.note_add
      xpReward: 30,
    ),
    DailyChallengeDefinition(
      id: 'replay_one',
      title: 'Replay a hand',
      description: 'Open a saved hand from the trainer.',
      target: 1,
      iconCodepoint: 0xe042, // Icons.history
      xpReward: 20,
    ),
  ];

  /// Lookup definition by id.
  static DailyChallengeDefinition? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Deterministically pick [dailyCount] challenges for [today]. The same
  /// calendar day yields the same set; consecutive days rotate through the
  /// catalogue. Picks distinct ids.
  static List<DailyChallenge> forDate(DateTime today) {
    final day = Progression.dayKey(today);
    final seed = day.day + day.month * 31 + day.year * 372;
    final indices = <int>[];
    var cursor = seed;
    while (indices.length < dailyCount && indices.length < all.length) {
      cursor = _xorshift(cursor);
      final pick = (cursor & 0x7fffffff) % all.length;
      if (!indices.contains(pick)) indices.add(pick);
    }
    return indices
        .map((i) => DailyChallenge(
              definitionId: all[i].id,
              progress: 0,
              completed: false,
              date: day,
            ))
        .toList(growable: false);
  }

  /// Encode the snapshot wrapper persisted by the service.
  static String encodeSnapshot(DateTime date, List<DailyChallenge> list) {
    return jsonEncode({
      'date': _yyyyMmDd(date),
      'challenges': list.map((c) => c.toJson()).toList(),
    });
  }

  /// Returns null when [raw] is missing/corrupt or the stored date doesn't
  /// match [today].
  static List<DailyChallenge>? tryDecodeForToday(String? raw, DateTime today) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final data = jsonDecode(raw);
      if (data is! Map<String, dynamic>) return null;
      final dateStr = data['date'];
      if (dateStr is! String) return null;
      final stored = _parseYyyyMmDd(dateStr);
      if (stored == null) return null;
      if (Progression.dayKey(stored) != Progression.dayKey(today)) {
        return null;
      }
      final list = data['challenges'];
      if (list is! List) return null;
      final out = <DailyChallenge>[];
      for (final entry in list) {
        if (entry is Map<String, dynamic>) {
          final c = DailyChallenge.tryFromJson(entry);
          if (c != null) out.add(c);
        }
      }
      // Drop any entries whose definition has been retired.
      return out.where((c) => byId(c.definitionId) != null).toList();
    } catch (_) {
      return null;
    }
  }

  /// Apply a delta to the matching challenge id. Returns the updated list and
  /// a flag indicating whether the challenge transitioned from incomplete to
  /// complete on this call (so the caller can grant XP exactly once).
  static IncrementResult applyIncrement(
    List<DailyChallenge> current,
    String challengeId,
    int amount,
  ) {
    final idx = current.indexWhere((c) => c.definitionId == challengeId);
    if (idx < 0 || amount <= 0) {
      return IncrementResult(
        list: current,
        justCompleted: null,
      );
    }
    final ch = current[idx];
    if (ch.completed) {
      return IncrementResult(list: current, justCompleted: null);
    }
    final def = byId(challengeId);
    if (def == null) return IncrementResult(list: current, justCompleted: null);
    final newProgress = (ch.progress + amount).clamp(0, def.target);
    final completed = newProgress >= def.target;
    final updated = ch.copyWith(progress: newProgress, completed: completed);
    final out = List<DailyChallenge>.from(current);
    out[idx] = updated;
    return IncrementResult(
      list: out,
      justCompleted: completed ? updated : null,
    );
  }
}

/// Outcome returned by [DailyChallenges.applyIncrement].
class IncrementResult {
  final List<DailyChallenge> list;

  /// Non-null when this increment finished the challenge — the caller should
  /// grant `xpReward` and surface a celebratory toast exactly once.
  final DailyChallenge? justCompleted;

  const IncrementResult({required this.list, required this.justCompleted});
}

String _yyyyMmDd(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

DateTime? _parseYyyyMmDd(String raw) {
  final parts = raw.split('-');
  if (parts.length != 3) return DateTime.tryParse(raw);
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

/// Small xorshift step — keeps the daily picker reproducible without pulling
/// in [math.Random].
int _xorshift(int x) {
  x ^= (x << 13) & 0x7fffffff;
  x ^= (x >> 7);
  x ^= (x << 17) & 0x7fffffff;
  if (x == 0) x = 0x12345;
  return x & 0x7fffffff;
}
