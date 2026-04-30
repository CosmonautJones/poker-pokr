import 'dart:convert';

import 'package:flutter/material.dart';

import 'user_stats.dart';

/// Tier rarity for an achievement. Drives gradient and rim treatment in the
/// gallery and unlock toast.
enum AchievementTier { bronze, silver, gold, platinum }

/// Domain bucket — used by the gallery to group rows.
enum AchievementCategory { milestone, streak, mastery, discovery }

/// Static definition of a single achievement.
///
/// Pure data: no Flutter widgets. Renderers map the [icon] to a Material icon.
@immutable
class AchievementDef {
  final String id;
  final String title;
  final String description;
  final String hint;
  final IconData icon;
  final AchievementTier tier;
  final AchievementCategory category;
  final bool Function(UserStats stats) isUnlocked;

  const AchievementDef({
    required this.id,
    required this.title,
    required this.description,
    required this.hint,
    required this.icon,
    required this.tier,
    required this.category,
    required this.isUnlocked,
  });
}

/// Curated catalog of achievements. Order here is the canonical display order
/// inside each category, sorted from easiest to hardest.
abstract final class AchievementCatalog {
  static final List<AchievementDef> all = [
    AchievementDef(
      id: 'first_hand',
      title: 'First Deal',
      description: 'Complete your first hand.',
      hint: 'Play a hand to the river.',
      icon: Icons.style_rounded,
      tier: AchievementTier.bronze,
      category: AchievementCategory.milestone,
      isUnlocked: (s) => s.handsPlayed >= 1,
    ),
    AchievementDef(
      id: 'hands_50',
      title: 'Regular',
      description: 'Play 50 hands.',
      hint: 'Keep dealing — reps build instincts.',
      icon: Icons.casino_rounded,
      tier: AchievementTier.bronze,
      category: AchievementCategory.milestone,
      isUnlocked: (s) => s.handsPlayed >= 50,
    ),
    AchievementDef(
      id: 'hands_500',
      title: 'Grinder',
      description: 'Play 500 hands.',
      hint: 'Volume is the price of skill.',
      icon: Icons.local_fire_department_rounded,
      tier: AchievementTier.silver,
      category: AchievementCategory.milestone,
      isUnlocked: (s) => s.handsPlayed >= 500,
    ),
    AchievementDef(
      id: 'hands_1000',
      title: 'Marathon',
      description: 'Play 1,000 hands.',
      hint: 'Long-haul commitment.',
      icon: Icons.emoji_events_rounded,
      tier: AchievementTier.gold,
      category: AchievementCategory.milestone,
      isUnlocked: (s) => s.handsPlayed >= 1000,
    ),
    AchievementDef(
      id: 'streak_3',
      title: 'Habit Forming',
      description: 'Play 3 days in a row.',
      hint: 'Three consecutive days.',
      icon: Icons.bolt_rounded,
      tier: AchievementTier.bronze,
      category: AchievementCategory.streak,
      isUnlocked: (s) => s.bestStreakDays >= 3,
    ),
    AchievementDef(
      id: 'streak_7',
      title: 'Week of Cards',
      description: 'Play 7 days in a row.',
      hint: 'A full week of practice.',
      icon: Icons.calendar_view_week_rounded,
      tier: AchievementTier.silver,
      category: AchievementCategory.streak,
      isUnlocked: (s) => s.bestStreakDays >= 7,
    ),
    AchievementDef(
      id: 'streak_30',
      title: 'Iron Discipline',
      description: 'Play 30 days in a row.',
      hint: 'A month of daily reps.',
      icon: Icons.shield_rounded,
      tier: AchievementTier.gold,
      category: AchievementCategory.streak,
      isUnlocked: (s) => s.bestStreakDays >= 30,
    ),
    AchievementDef(
      id: 'lesson_first',
      title: 'Student',
      description: 'Complete your first lesson scenario.',
      hint: 'Tap Lessons → pick any scenario.',
      icon: Icons.menu_book_rounded,
      tier: AchievementTier.bronze,
      category: AchievementCategory.mastery,
      isUnlocked: (s) => s.lessonsCompleted >= 1,
    ),
    AchievementDef(
      id: 'lessons_5',
      title: 'Scholar',
      description: 'Complete 5 lesson scenarios.',
      hint: 'Five scenarios cleared.',
      icon: Icons.school_rounded,
      tier: AchievementTier.silver,
      category: AchievementCategory.mastery,
      isUnlocked: (s) => s.lessonsCompleted >= 5,
    ),
    AchievementDef(
      id: 'level_5',
      title: 'On the Rise',
      description: 'Reach level 5.',
      hint: 'Earn enough XP for level 5.',
      icon: Icons.trending_up_rounded,
      tier: AchievementTier.silver,
      category: AchievementCategory.mastery,
      isUnlocked: (s) => s.level >= 5,
    ),
    AchievementDef(
      id: 'level_10',
      title: 'Sharp',
      description: 'Reach level 10.',
      hint: 'Push to level 10.',
      icon: Icons.psychology_rounded,
      tier: AchievementTier.gold,
      category: AchievementCategory.mastery,
      isUnlocked: (s) => s.level >= 10,
    ),
    AchievementDef(
      id: 'xp_1000',
      title: 'Four-Figure Mind',
      description: 'Earn 1,000 lifetime XP.',
      hint: 'Stack a thousand XP.',
      icon: Icons.auto_awesome_rounded,
      tier: AchievementTier.silver,
      category: AchievementCategory.discovery,
      isUnlocked: (s) => s.totalXp >= 1000,
    ),
  ];

  static AchievementDef byId(String id) =>
      all.firstWhere((a) => a.id == id, orElse: () => all.first);

  static List<AchievementDef> inCategory(AchievementCategory c) =>
      all.where((a) => a.category == c).toList(growable: false);
}

/// Persistable map of unlocked achievements → unlock timestamp (UTC).
@immutable
class AchievementsState {
  static const storageKey = 'achievements_v1';

  /// Map of achievement id → unlocked-at instant.
  final Map<String, DateTime> unlocked;

  const AchievementsState({this.unlocked = const {}});

  const AchievementsState.empty() : unlocked = const {};

  AchievementsState copyWith({Map<String, DateTime>? unlocked}) =>
      AchievementsState(unlocked: unlocked ?? this.unlocked);

  bool isUnlocked(String id) => unlocked.containsKey(id);

  int get unlockedCount => unlocked.length;

  /// Determine which achievements should be unlocked given [stats] and return
  /// the set of newly-eligible ids (not yet present in [unlocked]).
  Set<String> evaluateNew(UserStats stats) {
    final fresh = <String>{};
    for (final def in AchievementCatalog.all) {
      if (unlocked.containsKey(def.id)) continue;
      if (def.isUnlocked(stats)) fresh.add(def.id);
    }
    return fresh;
  }

  /// Return a copy with the given ids stamped at [now].
  AchievementsState withUnlocked(Iterable<String> ids, DateTime now) {
    if (ids.isEmpty) return this;
    final next = Map<String, DateTime>.from(unlocked);
    for (final id in ids) {
      next.putIfAbsent(id, () => now);
    }
    return copyWith(unlocked: next);
  }

  Map<String, dynamic> toJson() => {
        for (final e in unlocked.entries) e.key: e.value.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  static AchievementsState? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final out = <String, DateTime>{};
      map.forEach((k, v) {
        if (v is String) {
          final dt = DateTime.tryParse(v);
          if (dt != null) out[k] = dt;
        }
      });
      return AchievementsState(unlocked: out);
    } catch (_) {
      return null;
    }
  }
}
