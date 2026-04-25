import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/scenario_mastery.dart';
import 'package:poker_trainer/core/progression/user_stats.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';

/// Displays all available poker lessons with per-lesson mastery summaries.
class LessonsListScreen extends ConsumerWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(userStatsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        _MasterySummary(stats: stats),
        const SizedBox(height: 12),
        for (final lesson in lessonsCatalog)
          _LessonCard(lesson: lesson, stats: stats),
      ],
    );
  }
}

/// Top-of-list summary: total stars earned across the catalog plus a
/// progress bar against the maximum possible.
class _MasterySummary extends StatelessWidget {
  final UserStats stats;

  const _MasterySummary({required this.stats});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    var earnedStars = 0;
    var totalScenarios = 0;
    var masteredScenarios = 0;
    for (final lesson in lessonsCatalog) {
      for (var i = 0; i < lesson.scenarios.length; i++) {
        totalScenarios += 1;
        final key = scenarioKeyFor(lesson.id, i);
        final rec = stats.scenarioMastery[key];
        if (rec != null) {
          earnedStars += rec.bestStars;
          if (rec.bestStars >= 1) masteredScenarios += 1;
        }
      }
    }
    final maxStars = totalScenarios * 3;
    final pct = maxStars == 0 ? 0.0 : earnedStars / maxStars;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: pt.goldPrimary.withValues(alpha: 0.25),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              pt.goldPrimary.withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome_rounded,
                    size: 16, color: pt.goldPrimary),
                const SizedBox(width: 6),
                Text(
                  'Mastery',
                  style: TextStyle(
                    color: pt.goldPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Text(
                  '$masteredScenarios / $totalScenarios completed',
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.star_rounded, size: 18, color: pt.goldPrimary),
                const SizedBox(width: 4),
                Text(
                  '$earnedStars',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                  ),
                ),
                Text(
                  ' / $maxStars stars',
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(pt.goldPrimary),
              ),
            ),
          ],
        ),
      ),
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

    var earnedStars = 0;
    var completedScenarios = 0;
    final scenarioCount = lesson.scenarios.length;
    for (var i = 0; i < scenarioCount; i++) {
      final key = scenarioKeyFor(lesson.id, i);
      final rec = stats.scenarioMastery[key];
      if (rec != null) {
        earnedStars += rec.bestStars;
        if (rec.bestStars >= 1) completedScenarios += 1;
      }
    }
    final maxStars = scenarioCount * 3;
    final isComplete =
        completedScenarios == scenarioCount && scenarioCount > 0;
    final isFullyMastered = earnedStars == maxStars && maxStars > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isFullyMastered
              ? pt.goldPrimary.withValues(alpha: 0.6)
              : pt.borderSubtle.withValues(alpha: 0.3),
          width: isFullyMastered ? 1.2 : 1,
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
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [pt.goldPrimary, pt.goldDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      lessonIcon(lesson.iconCodePoint),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lesson.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (isFullyMastered)
                              Icon(
                                Icons.workspace_premium_rounded,
                                color: pt.goldPrimary,
                                size: 18,
                              )
                            else if (isComplete)
                              Icon(
                                Icons.check_circle_rounded,
                                color: pt.profit,
                                size: 18,
                              ),
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
                  Icon(Icons.chevron_right_rounded, color: pt.textMuted),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star_rounded,
                      size: 14, color: pt.goldPrimary),
                  const SizedBox(width: 3),
                  Text(
                    '$earnedStars / $maxStars',
                    style: TextStyle(
                      color: pt.goldLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$completedScenarios / $scenarioCount '
                    'scenario${scenarioCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: pt.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: maxStars == 0 ? 0 : earnedStars / maxStars,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(pt.goldPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
