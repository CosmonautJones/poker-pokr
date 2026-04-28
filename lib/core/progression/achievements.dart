import 'dart:convert';

import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Categories surface as filter chips / colored accents on the progression
/// screen. Keep the set small and stable — values are persisted by name.
enum AchievementCategory { milestone, skill, streak, mastery }

/// Compile-time definition of a single achievement.
///
/// Definitions are static; only the per-user [Achievement] state (whether the
/// player has unlocked it and when) is persisted.
class AchievementDefinition {
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;

  /// Material icon code point. Stored as `int` so the definition list could
  /// be JSON-serialized for tooling without pulling in [IconData].
  final int iconCodepoint;

  const AchievementDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconCodepoint,
  });

  IconData get icon =>
      IconData(iconCodepoint, fontFamily: 'MaterialIcons');
}

/// Per-user achievement state — paired by [definitionId] with an
/// [AchievementDefinition].
class Achievement {
  final String definitionId;
  final DateTime? unlockedAt;

  const Achievement({required this.definitionId, this.unlockedAt});

  bool get isUnlocked => unlockedAt != null;

  Achievement copyWith({DateTime? unlockedAt}) => Achievement(
        definitionId: definitionId,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'definitionId': definitionId,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  static Achievement? tryFromJson(Map<String, dynamic> map) {
    final id = map['definitionId'];
    if (id is! String) return null;
    final unlockedAtRaw = map['unlockedAt'];
    return Achievement(
      definitionId: id,
      unlockedAt:
          unlockedAtRaw is String ? DateTime.tryParse(unlockedAtRaw) : null,
    );
  }

  static String encodeList(List<Achievement> list) =>
      jsonEncode(list.map((a) => a.toJson()).toList());

  static List<Achievement>? tryDecodeList(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return null;
      final result = <Achievement>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          final a = Achievement.tryFromJson(item);
          if (a != null) result.add(a);
        }
      }
      return result;
    } catch (_) {
      return null;
    }
  }
}

/// Catalog of all achievements shipped with the app.
///
/// Definition ids are stable strings — never rename, only deprecate. The
/// list is intentionally small (10) so the progression screen feels curated.
abstract final class Achievements {
  /// SharedPreferences key used by the service layer.
  static const storageKey = 'achievements_v1';

  static const all = <AchievementDefinition>[
    AchievementDefinition(
      id: 'first_hand',
      title: 'First Deal',
      description: 'Play your first hand.',
      category: AchievementCategory.milestone,
      iconCodepoint: 0xe5d5, // Icons.casino_rounded
    ),
    AchievementDefinition(
      id: 'ten_hands',
      title: 'Getting Warm',
      description: 'Play 10 hands.',
      category: AchievementCategory.milestone,
      iconCodepoint: 0xef76, // Icons.local_fire_department_rounded
    ),
    AchievementDefinition(
      id: 'hundred_hands',
      title: 'Grinder',
      description: 'Play 100 hands.',
      category: AchievementCategory.milestone,
      iconCodepoint: 0xea65, // Icons.workspace_premium_rounded
    ),
    AchievementDefinition(
      id: 'first_showdown_win',
      title: 'Down to the Felt',
      description: 'Win your first showdown.',
      category: AchievementCategory.skill,
      iconCodepoint: 0xea1b, // Icons.emoji_events_rounded
    ),
    AchievementDefinition(
      id: 'underdog_win',
      title: 'Cinderella',
      description:
          'Win a showdown as the equity underdog (less than 40% at the river).',
      category: AchievementCategory.skill,
      iconCodepoint: 0xe838, // Icons.star_rounded
    ),
    AchievementDefinition(
      id: 'nutted',
      title: 'Stone Cold',
      description: 'Make the nuts (best possible hand) at showdown.',
      category: AchievementCategory.mastery,
      iconCodepoint: 0xe87d, // Icons.favorite_rounded (placeholder gem-like)
    ),
    AchievementDefinition(
      id: 'first_lesson',
      title: 'Student of the Game',
      description: 'Complete your first lesson.',
      category: AchievementCategory.mastery,
      iconCodepoint: 0xe80c, // Icons.school_rounded
    ),
    AchievementDefinition(
      id: 'three_lessons',
      title: 'Curious Mind',
      description: 'Complete 3 lessons.',
      category: AchievementCategory.mastery,
      iconCodepoint: 0xe865, // Icons.menu_book_rounded
    ),
    AchievementDefinition(
      id: 'streak_3',
      title: 'Hot Hand',
      description: 'Reach a 3-day streak.',
      category: AchievementCategory.streak,
      iconCodepoint: 0xef76, // Icons.local_fire_department_rounded
    ),
    AchievementDefinition(
      id: 'streak_7',
      title: 'On Fire',
      description: 'Reach a 7-day streak.',
      category: AchievementCategory.streak,
      iconCodepoint: 0xe51c, // Icons.bolt_rounded
    ),
  ];

  /// Lookup by [id]. Returns `null` if not found (e.g. older clients reading
  /// a definition that has since been retired).
  static AchievementDefinition? byId(String id) {
    for (final d in all) {
      if (d.id == id) return d;
    }
    return null;
  }

  /// Default state for a fresh install: every definition, all locked.
  static List<Achievement> defaults() =>
      all.map((d) => Achievement(definitionId: d.id)).toList(growable: true);

  /// Pure rule engine.
  ///
  /// Returns a new list mirroring [current] with any newly-met conditions
  /// flipped to unlocked at [now] (default [DateTime.now]). Already-unlocked
  /// achievements are preserved. Definitions present in the catalog but
  /// missing from [current] are appended (locked).
  static List<Achievement> evaluate({
    required List<Achievement> current,
    required UserStats stats,
    AchievementContext? ctx,
    DateTime? now,
  }) {
    final ts = now ?? DateTime.now();
    final c = ctx ?? const AchievementContext();
    final existing = {for (final a in current) a.definitionId: a};

    bool conditionMet(String id) {
      switch (id) {
        case 'first_hand':
          return stats.handsPlayed >= 1;
        case 'ten_hands':
          return stats.handsPlayed >= 10;
        case 'hundred_hands':
          return stats.handsPlayed >= 100;
        case 'first_showdown_win':
          return c.wonShowdown;
        case 'underdog_win':
          final eq = c.riverEquity;
          return c.wonShowdown && eq != null && eq < 0.4;
        case 'nutted':
          return c.isNuts;
        case 'first_lesson':
          return stats.lessonsCompleted >= 1;
        case 'three_lessons':
          return stats.lessonsCompleted >= 3;
        case 'streak_3':
          return stats.streakDays >= 3 || stats.bestStreakDays >= 3;
        case 'streak_7':
          return stats.streakDays >= 7 || stats.bestStreakDays >= 7;
        default:
          return false;
      }
    }

    return all.map((def) {
      final prior = existing[def.id] ?? Achievement(definitionId: def.id);
      if (prior.isUnlocked) return prior;
      if (conditionMet(def.id)) {
        return prior.copyWith(unlockedAt: ts);
      }
      return prior;
    }).toList(growable: false);
  }

  /// Diff helper — entries unlocked in [next] that were locked in [prev].
  static List<Achievement> newlyUnlocked({
    required List<Achievement> prev,
    required List<Achievement> next,
  }) {
    final priorById = {for (final a in prev) a.definitionId: a};
    final out = <Achievement>[];
    for (final n in next) {
      final p = priorById[n.definitionId];
      if (n.isUnlocked && (p == null || !p.isUnlocked)) {
        out.add(n);
      }
    }
    return out;
  }
}

/// Optional context passed to [AchievementsNotifier.evaluate] so we can score
/// outcomes that aren't reflected in [UserStats] alone (showdown wins,
/// nuts, river equity).
class AchievementContext {
  final bool wonShowdown;
  final bool isNuts;
  final double? riverEquity;

  const AchievementContext({
    this.wonShowdown = false,
    this.isNuts = false,
    this.riverEquity,
  });
}
