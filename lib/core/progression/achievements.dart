/// Achievement catalog and pure-logic unlock engine.
///
/// Achievements are derived deterministically from [UserStats] and
/// [LessonProgress] so the engine has no side effects and is easy to test.
/// Persistence of "first seen" is layered separately via SharedPreferences
/// so we can render an unlock celebration exactly once per achievement.
library;

import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';

/// Visual category - drives icon + color in presentation.
enum AchievementCategory { play, streak, mastery, level }

/// Static achievement definition.
class Achievement {
  /// Stable id used for persistence. Never rename in place.
  final String id;
  final String title;
  final String description;
  final AchievementCategory category;

  /// Material icon code point. Stored as int so this file stays Flutter-free.
  final int iconCodePoint;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.iconCodePoint,
  });
}

/// All achievement definitions. Order is stable so the catalog screen can
/// iterate directly. The codepoints reference standard Material icons.
const List<Achievement> kAchievements = [
  // Play milestones
  Achievement(
    id: 'first_hand',
    title: 'Dealt In',
    description: 'Finish your first practice hand.',
    category: AchievementCategory.play,
    iconCodePoint: 0xe037, // play_circle_filled_rounded
  ),
  Achievement(
    id: 'ten_hands',
    title: 'Grinder',
    description: 'Play 10 hands.',
    category: AchievementCategory.play,
    iconCodePoint: 0xe838, // star_rounded
  ),
  Achievement(
    id: 'fifty_hands',
    title: 'Volume Player',
    description: 'Play 50 hands.',
    category: AchievementCategory.play,
    iconCodePoint: 0xe263, // wb_iridescent_rounded
  ),
  Achievement(
    id: 'hundred_hands',
    title: 'Centurion',
    description: 'Play 100 hands.',
    category: AchievementCategory.play,
    iconCodePoint: 0xe7fb, // people_alt_rounded
  ),

  // Streak milestones
  Achievement(
    id: 'streak_3',
    title: 'On Fire',
    description: 'Play 3 days in a row.',
    category: AchievementCategory.streak,
    iconCodePoint: 0xea14, // local_fire_department_rounded
  ),
  Achievement(
    id: 'streak_7',
    title: 'Weekly Warrior',
    description: 'Play 7 days in a row.',
    category: AchievementCategory.streak,
    iconCodePoint: 0xea14, // local_fire_department_rounded
  ),
  Achievement(
    id: 'streak_30',
    title: 'Discipline',
    description: 'Play 30 days in a row.',
    category: AchievementCategory.streak,
    iconCodePoint: 0xea14, // local_fire_department_rounded
  ),

  // Lesson mastery
  Achievement(
    id: 'first_lesson',
    title: 'Student',
    description: 'Complete your first lesson scenario.',
    category: AchievementCategory.mastery,
    iconCodePoint: 0xe559, // school_rounded
  ),
  Achievement(
    id: 'lesson_chapter',
    title: 'Chapter Cleared',
    description: 'Complete every scenario in any lesson.',
    category: AchievementCategory.mastery,
    iconCodePoint: 0xe865, // menu_book_rounded
  ),
  Achievement(
    id: 'all_lessons',
    title: 'Theory Master',
    description: 'Complete every scenario in every lesson.',
    category: AchievementCategory.mastery,
    iconCodePoint: 0xe80c, // emoji_events_rounded
  ),

  // Level milestones
  Achievement(
    id: 'level_3',
    title: 'Rising',
    description: 'Reach level 3.',
    category: AchievementCategory.level,
    iconCodePoint: 0xe87d, // trending_up_rounded
  ),
  Achievement(
    id: 'level_5',
    title: 'Sharp',
    description: 'Reach level 5.',
    category: AchievementCategory.level,
    iconCodePoint: 0xe838, // star_rounded
  ),
  Achievement(
    id: 'level_10',
    title: 'Pro Mindset',
    description: 'Reach level 10.',
    category: AchievementCategory.level,
    iconCodePoint: 0xe80c, // emoji_events_rounded
  ),
];

/// Stateless deterministic engine. Given the player's stats and lesson
/// progress (and the lesson catalog so chapter completion can be checked),
/// returns the set of currently-unlocked achievement ids.
abstract final class AchievementsEngine {
  /// Evaluate all unlocks. Pure — same inputs always yield the same output.
  static Set<String> evaluate({
    required UserStats stats,
    required LessonProgress lessonProgress,
    required List<Lesson> lessons,
  }) {
    final unlocked = <String>{};

    if (stats.handsPlayed >= 1) unlocked.add('first_hand');
    if (stats.handsPlayed >= 10) unlocked.add('ten_hands');
    if (stats.handsPlayed >= 50) unlocked.add('fifty_hands');
    if (stats.handsPlayed >= 100) unlocked.add('hundred_hands');

    final bestStreak =
        stats.bestStreakDays > stats.streakDays
            ? stats.bestStreakDays
            : stats.streakDays;
    if (bestStreak >= 3) unlocked.add('streak_3');
    if (bestStreak >= 7) unlocked.add('streak_7');
    if (bestStreak >= 30) unlocked.add('streak_30');

    if (lessonProgress.totalScenariosCompleted >= 1) {
      unlocked.add('first_lesson');
    }

    var anyChapterFull = false;
    var allChaptersFull = lessons.isNotEmpty;
    for (final lesson in lessons) {
      final total = lesson.scenarios.length;
      final done = lessonProgress.completedCount(lesson.id);
      if (total > 0 && done >= total) {
        anyChapterFull = true;
      } else {
        allChaptersFull = false;
      }
    }
    if (anyChapterFull) unlocked.add('lesson_chapter');
    if (allChaptersFull) unlocked.add('all_lessons');

    if (stats.level >= 3) unlocked.add('level_3');
    if (stats.level >= 5) unlocked.add('level_5');
    if (stats.level >= 10) unlocked.add('level_10');

    return unlocked;
  }

  /// Newly unlocked ids = current minus the prior snapshot.
  static Set<String> newlyUnlocked({
    required Set<String> previous,
    required Set<String> current,
  }) {
    return current.difference(previous);
  }
}
