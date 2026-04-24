import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';

/// Displays all available poker lessons with per-scenario progress and
/// a mastery badge when every scenario has been completed.
class LessonsListScreen extends ConsumerWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: lessonsCatalog.length,
      itemBuilder: (context, index) {
        final lesson = lessonsCatalog[index];
        return _LessonCard(lesson: lesson, stats: stats);
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final UserStats stats;

  const _LessonCard({required this.lesson, required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final total = lesson.scenarios.length;
    final completed = stats.completedScenarioCount(lesson.id);
    final progress = total == 0 ? 0.0 : completed / total;
    final mastered = total > 0 && completed >= total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: mastered
              ? pt.goldPrimary.withValues(alpha: 0.6)
              : pt.borderSubtle.withValues(alpha: 0.3),
          width: mastered ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/trainer/lesson/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon (gold gradient if mastered, muted otherwise)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: mastered
                            ? [pt.goldLight, pt.goldPrimary]
                            : [pt.goldPrimary, pt.goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: mastered
                          ? [
                              BoxShadow(
                                color: pt.goldPrimary.withValues(alpha: 0.35),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      lessonIcon(lesson.iconCodePoint),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (mastered) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.verified_rounded,
                                size: 18,
                                color: pt.goldPrimary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          lesson.subtitle,
                          style: TextStyle(
                            color: pt.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: pt.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _DifficultyBadge(difficulty: lesson.difficulty),
                  const SizedBox(width: 8),
                  _ScenarioProgressBadge(
                    completed: completed,
                    total: total,
                    mastered: mastered,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    mastered ? pt.goldPrimary : pt.profit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final LessonDifficulty difficulty;

  const _DifficultyBadge({required this.difficulty});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final (color, icon) = switch (difficulty) {
      LessonDifficulty.beginner => (pt.positionLate, Icons.school_rounded),
      LessonDifficulty.intermediate => (pt.accent, Icons.trending_up_rounded),
      LessonDifficulty.advanced => (pt.loss, Icons.local_fire_department_rounded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            difficulty.label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioProgressBadge extends StatelessWidget {
  final int completed;
  final int total;
  final bool mastered;

  const _ScenarioProgressBadge({
    required this.completed,
    required this.total,
    required this.mastered,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final color = mastered ? pt.goldPrimary : pt.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          mastered
              ? Icons.workspace_premium_rounded
              : Icons.check_circle_outline_rounded,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          mastered ? 'Mastered' : '$completed / $total scenarios',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
