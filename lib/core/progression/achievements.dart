import 'dart:convert';

import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';

enum AchievementCategory { firstSteps, streak, grind, mastery, profit, skill }

enum AchievementRarity { common, rare, epic, legendary }

class Achievement {
  final String id;
  final String title;
  final String description;
  final int iconCodePoint;
  final AchievementCategory category;
  final AchievementRarity rarity;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconCodePoint,
    required this.category,
    required this.rarity,
  });
}

class AchievementProgress {
  static const storageKey = 'achievements_v1';

  final Map<String, DateTime> unlockedAt;

  const AchievementProgress({required this.unlockedAt});

  const AchievementProgress.empty() : unlockedAt = const {};

  AchievementProgress copyWith({Map<String, DateTime>? unlockedAt}) {
    return AchievementProgress(
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  bool isUnlocked(String id) => unlockedAt.containsKey(id);

  int get unlockedCount => unlockedAt.length;

  String encode() {
    final map = unlockedAt
        .map((key, value) => MapEntry(key, value.toIso8601String()));
    return jsonEncode(map);
  }

  static AchievementProgress? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final out = <String, DateTime>{};
      decoded.forEach((key, value) {
        if (value is String) {
          final dt = DateTime.tryParse(value);
          if (dt != null) out[key] = dt;
        }
      });
      return AchievementProgress(unlockedAt: out);
    } catch (_) {
      return null;
    }
  }
}

abstract final class AchievementsCatalog {
  static const List<Achievement> all = [
    Achievement(
      id: 'first_hand',
      title: 'First Hand',
      description: 'Complete your very first hand at the practice table.',
      iconCodePoint: 0xe037,
      category: AchievementCategory.firstSteps,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'first_lesson',
      title: 'Student of the Game',
      description: 'Finish your first lesson scenario.',
      iconCodePoint: 0xe80c,
      category: AchievementCategory.firstSteps,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Warming Up',
      description: 'Play on three consecutive days.',
      iconCodePoint: 0xef55,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'streak_7',
      title: 'On Fire',
      description: 'Maintain a 7-day play streak.',
      iconCodePoint: 0xef55,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Ironclad Discipline',
      description: 'Hit a 30-day streak without missing a day.',
      iconCodePoint: 0xef55,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'hands_10',
      title: 'Dealer\'s Favorite',
      description: 'Play 10 hands at the training table.',
      iconCodePoint: 0xe037,
      category: AchievementCategory.grind,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'hands_50',
      title: 'Grinder',
      description: 'Play 50 hands at the training table.',
      iconCodePoint: 0xe037,
      category: AchievementCategory.grind,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'hands_250',
      title: 'Rail to Rail',
      description: 'Play 250 hands at the training table.',
      iconCodePoint: 0xe037,
      category: AchievementCategory.grind,
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'lessons_5',
      title: 'Sharp Study',
      description: 'Complete five lesson scenarios.',
      iconCodePoint: 0xe80c,
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'lessons_all',
      title: 'Table Scholar',
      description: 'Complete every lesson in the catalog.',
      iconCodePoint: 0xe80c,
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.legendary,
    ),
    Achievement(
      id: 'level_5',
      title: 'Rising Stakes',
      description: 'Reach player level 5.',
      iconCodePoint: 0xe838,
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'level_10',
      title: 'High Roller',
      description: 'Reach player level 10.',
      iconCodePoint: 0xe838,
      category: AchievementCategory.mastery,
      rarity: AchievementRarity.epic,
    ),
    Achievement(
      id: 'first_session',
      title: 'On the Books',
      description: 'Log your first live session in the Bookkeeper.',
      iconCodePoint: 0xe85d,
      category: AchievementCategory.firstSteps,
      rarity: AchievementRarity.common,
    ),
    Achievement(
      id: 'bankroll_positive',
      title: 'In the Black',
      description: 'Log a session with a positive profit.',
      iconCodePoint: 0xe1db,
      category: AchievementCategory.profit,
      rarity: AchievementRarity.rare,
    ),
    Achievement(
      id: 'sharp_mind',
      title: 'Sharp Mind',
      description: 'Complete 3 lessons to hone your reads.',
      iconCodePoint: 0xe80c,
      category: AchievementCategory.skill,
      rarity: AchievementRarity.common,
    ),
  ];

  static Achievement? byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  static List<Achievement> evaluate({
    required UserStats stats,
    required AchievementProgress current,
    required DateTime now,
    int? latestSessionProfitCents,
  }) {
    final unlocks = <Achievement>[];

    void consider(String id, bool condition) {
      if (!condition) return;
      if (current.isUnlocked(id)) return;
      final achievement = byId(id);
      if (achievement == null) return;
      unlocks.add(achievement);
    }

    consider('first_hand', stats.handsPlayed >= 1);
    consider('first_lesson', stats.lessonsCompleted >= 1);
    consider('streak_3', stats.streakDays >= 3 || stats.bestStreakDays >= 3);
    consider('streak_7', stats.streakDays >= 7 || stats.bestStreakDays >= 7);
    consider(
      'streak_30',
      stats.streakDays >= 30 || stats.bestStreakDays >= 30,
    );
    consider('hands_10', stats.handsPlayed >= 10);
    consider('hands_50', stats.handsPlayed >= 50);
    consider('hands_250', stats.handsPlayed >= 250);
    consider('lessons_5', stats.lessonsCompleted >= 5);
    consider('sharp_mind', stats.lessonsCompleted >= 3);

    final totalScenarios =
        lessonsCatalog.fold<int>(0, (acc, l) => acc + l.scenarios.length);
    consider(
      'lessons_all',
      totalScenarios > 0 && stats.lessonsCompleted >= totalScenarios,
    );

    consider('level_5', stats.level >= 5);
    consider('level_10', stats.level >= 10);

    if (latestSessionProfitCents != null) {
      consider('first_session', true);
      consider('bankroll_positive', latestSessionProfitCents > 0);
    }

    return unlocks;
  }
}
