import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/progression/scenario_mastery.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Shows lesson introduction and list of scenarios to play.
class LessonDetailScreen extends ConsumerWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final lesson = lessonsCatalog.where((l) => l.id == lessonId).firstOrNull;
    final mastery = ref.watch(userStatsProvider).scenarioMastery;

    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(child: Text('Lesson not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/trainer'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: pt.goldPrimary.withValues(alpha: 0.3),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        lessonIcon(lesson.iconCodePoint),
                        color: pt.goldPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Overview',
                        style: TextStyle(
                          color: pt.goldPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    lesson.introduction,
                    style: TextStyle(
                      color: pt.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scenarios',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: pt.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < lesson.scenarios.length; i++)
            _ScenarioCard(
              scenario: lesson.scenarios[i],
              index: i,
              record:
                  mastery[scenarioKeyFor(lessonId, i)] ?? const MasteryRecord.empty(),
              onPlay: () {
                context.go('/trainer/lesson/$lessonId/play/$i');
              },
            ),
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  final LessonScenario scenario;
  final int index;
  final MasteryRecord record;
  final VoidCallback onPlay;

  const _ScenarioCard({
    required this.scenario,
    required this.index,
    required this.record,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final gameLabel = scenario.gameType == GameType.omaha ? 'PLO' : "Hold'em";
    final stars = record.bestStars;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: stars >= 3
              ? pt.goldPrimary.withValues(alpha: 0.55)
              : pt.borderSubtle.withValues(alpha: 0.25),
          width: stars >= 3 ? 1.2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: pt.feltCenter,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scenario.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          scenario.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: pt.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pt.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          gameLabel,
                          style: TextStyle(
                            color: pt.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        Icons.play_arrow_rounded,
                        color: pt.profit,
                        size: 22,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _MasteryRow(record: record),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact star row + helper text describing mastery state.
class _MasteryRow extends StatelessWidget {
  final MasteryRecord record;

  const _MasteryRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final stars = record.bestStars;
    final hint = _hintFor(stars, record);

    return Row(
      children: [
        for (int s = 1; s <= 3; s++)
          Padding(
            padding: const EdgeInsets.only(right: 2),
            child: Icon(
              s <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 16,
              color: s <= stars
                  ? pt.goldPrimary
                  : pt.textMuted.withValues(alpha: 0.45),
            ),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            hint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: pt.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  String _hintFor(int stars, MasteryRecord record) {
    switch (stars) {
      case 0:
        return 'Not started';
      case 1:
        return 'Try again without undo for 2 stars';
      case 2:
        final remaining = 3 - record.cleanCompletions;
        return remaining > 0
            ? '$remaining more clean run${remaining == 1 ? '' : 's'} for 3 stars'
            : 'Mastered';
      default:
        return 'Mastered • ${record.completions} plays';
    }
  }
}
