import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lesson_progress.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/screens/lesson_icons.dart';
import 'package:poker_trainer/features/trainer/providers/lesson_progress_provider.dart';

/// Displays all available poker lessons as a scrollable list of cards.
class LessonsListScreen extends ConsumerWidget {
  const LessonsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(lessonProgressProvider);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: lessonsCatalog.length,
      itemBuilder: (context, index) {
        final lesson = lessonsCatalog[index];
        return _LessonCard(lesson: lesson, progress: progress);
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final Lesson lesson;
  final LessonProgress progress;

  const _LessonCard({required this.lesson, required this.progress});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final total = lesson.scenarios.length;
    final done = progress.completedCount(lesson.id);
    final ratio = total == 0 ? 0.0 : done / total;
    final isComplete = total > 0 && done >= total;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isComplete
              ? pt.profit.withValues(alpha: 0.5)
              : pt.borderSubtle.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/trainer/lesson/${lesson.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with completion ring
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: ratio,
                        strokeWidth: 3,
                        backgroundColor: pt.borderSubtle.withValues(alpha: 0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isComplete ? pt.profit : pt.goldPrimary,
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isComplete
                              ? [pt.profit, pt.profit.withValues(alpha: 0.7)]
                              : [pt.goldPrimary, pt.goldDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isComplete
                            ? Icons.check_rounded
                            : lessonIcon(lesson.iconCodePoint),
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
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
                      _progressLabel(done, total, isComplete),
                      style: TextStyle(
                        color: isComplete ? pt.profit : pt.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
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
        ),
      ),
    );
  }

  static String _progressLabel(int done, int total, bool complete) {
    if (complete) return 'Complete · $total/$total';
    if (done == 0) {
      return '$total scenario${total == 1 ? "" : "s"}';
    }
    return '$done / $total complete';
  }
}
