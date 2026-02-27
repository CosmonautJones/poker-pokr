import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';

/// Displays all available poker lessons as a scrollable list of cards.
class LessonsListScreen extends StatelessWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: lessonsCatalog.length,
      itemBuilder: (context, index) {
        final lesson = lessonsCatalog[index];
        return _LessonCard(lesson: lesson);
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;

  const _LessonCard({required this.lesson});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: pt.borderSubtle.withValues(alpha: 0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/trainer/lesson/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
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
                  IconData(lesson.iconCodePoint, fontFamily: 'MaterialIcons'),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      lesson.subtitle,
                      style: TextStyle(
                        color: pt.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${lesson.scenarios.length} scenario${lesson.scenarios.length > 1 ? "s" : ""}',
                      style: TextStyle(
                        color: pt.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: pt.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
