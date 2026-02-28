import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';
import 'package:poker_trainer/poker/models/game_type.dart';

/// Shows lesson introduction and list of scenarios to play.
class LessonDetailScreen extends StatelessWidget {
  final String lessonId;

  const LessonDetailScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final lesson = lessonsCatalog.where((l) => l.id == lessonId).firstOrNull;

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
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/trainer'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // Introduction card
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
          // Scenarios header
          Text(
            'Scenarios',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: pt.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          // Scenario cards
          for (var i = 0; i < lesson.scenarios.length; i++)
            _ScenarioCard(
              scenario: lesson.scenarios[i],
              index: i,
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
  final VoidCallback onPlay;

  const _ScenarioCard({
    required this.scenario,
    required this.index,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final gameLabel = scenario.gameType == GameType.omaha ? 'PLO' : "Hold'em";

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPlay,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Scenario number badge
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                  Icon(Icons.play_arrow, color: pt.profit, size: 22),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
