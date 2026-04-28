import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/progression/achievements.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/core/services/haptic_service.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';
import 'package:poker_trainer/features/trainer/domain/lessons_catalog.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/action_bar.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/coaching_banner.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/equity_display.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/poker_table_widget.dart';
import 'package:poker_trainer/features/trainer/providers/hand_replay_provider.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// Interactive lesson play screen.
///
/// Loads a [LessonScenario] with pre-stacked cards and shows coaching tips
/// as the player progresses through streets.
class LessonPlayScreen extends ConsumerStatefulWidget {
  final String lessonId;
  final int scenarioIndex;

  const LessonPlayScreen({
    super.key,
    required this.lessonId,
    required this.scenarioIndex,
  });

  @override
  ConsumerState<LessonPlayScreen> createState() => _LessonPlayScreenState();
}

class _LessonPlayScreenState extends ConsumerState<LessonPlayScreen> {
  HandSetup? _setup;
  LessonScenario? _scenario;
  bool _awardedCompletionXp = false;

  @override
  void initState() {
    super.initState();
    _loadScenario();
  }

  void _loadScenario() {
    final lesson =
        lessonsCatalog.where((l) => l.id == widget.lessonId).firstOrNull;
    if (lesson == null ||
        widget.scenarioIndex < 0 ||
        widget.scenarioIndex >= lesson.scenarios.length) {
      return;
    }

    final scenario = lesson.scenarios[widget.scenarioIndex];
    _scenario = scenario;

    // Build a HandSetup with a stacked deck so the community cards
    // come out in the exact order defined by the scenario.
    _setup = HandSetup(
      playerCount: scenario.playerCount,
      smallBlind: scenario.smallBlind,
      bigBlind: scenario.bigBlind,
      dealerIndex: scenario.dealerIndex,
      playerNames: scenario.playerNames,
      stacks: scenario.stacks,
      holeCards: scenario.holeCards,
      gameType: scenario.gameType,
      stackedDeck: scenario.buildStackedDeck(),
    );
  }

  /// Find the coaching tip for the current street.
  CoachingTip? _tipForStreet(Street street) {
    if (_scenario == null) return null;
    for (final tip in _scenario!.tips) {
      if (tip.street == street) return tip;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_setup == null || _scenario == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lesson')),
        body: const Center(child: Text('Scenario not found')),
      );
    }

    final setup = _setup!;
    final scenario = _scenario!;
    final replayState = ref.watch(handReplayProvider(setup));
    final notifier = ref.read(handReplayProvider(setup).notifier);
    final gs = replayState.gameState;

    final currentTip = _tipForStreet(gs.street);
    final hasNextScenario = _hasNextScenario();

    // Award XP + success haptic exactly once per completed scenario.
    if (replayState.isComplete && !_awardedCompletionXp) {
      _awardedCompletionXp = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(userStatsProvider.notifier)
            .recordLessonComplete(achievementContext: const AchievementContext());
        ref.read(hapticServiceProvider).success();
      });
    } else if (!replayState.isComplete && _awardedCompletionXp) {
      _awardedCompletionXp = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          scenario.title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/trainer/lesson/${widget.lessonId}'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo_rounded, size: 20),
            onPressed: replayState.canUndo ? () => notifier.undo() : null,
            tooltip: 'Undo',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.redo_rounded, size: 20),
            onPressed: replayState.canRedo ? () => notifier.redo() : null,
            tooltip: 'Redo',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      body: Column(
        children: [
          // Table
          Expanded(
            child: Stack(
              children: [
                PokerTableWidget(gameState: gs),
                if (replayState.isComplete)
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: _LessonCompleteConfetti(),
                    ),
                  ),
                if (replayState.isComplete)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 12,
                    child: Center(
                      child: _LessonCompleteOverlay(
                        onBack: () =>
                            context.go('/trainer/lesson/${widget.lessonId}'),
                        onNext: hasNextScenario ? _goToNextScenario : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Equity display
          if (!replayState.isComplete) EquityDisplay(gameState: gs),
          // Coaching banner
          if (!replayState.isComplete) CoachingBanner(tip: currentTip),
          // Action bar
          if (!replayState.isComplete)
            ActionBar(
              currentPlayerIndex: gs.currentPlayerIndex,
              legalActions: replayState.legalActions,
              currentPot: gs.pot,
              onAction: (action) => notifier.applyAction(action),
              gameType: gs.gameType,
            ),
        ],
      ),
    );
  }

  bool _hasNextScenario() {
    final lesson =
        lessonsCatalog.where((l) => l.id == widget.lessonId).firstOrNull;
    if (lesson == null) return false;
    return widget.scenarioIndex < lesson.scenarios.length - 1;
  }

  void _goToNextScenario() {
    final nextIndex = widget.scenarioIndex + 1;
    context.go('/trainer/lesson/${widget.lessonId}/play/$nextIndex');
  }
}

/// Overlay shown when a lesson scenario is complete.
class _LessonCompleteOverlay extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onNext;

  const _LessonCompleteOverlay({
    required this.onBack,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return Container(
      width: 280,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: pt.goldPrimary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: pt.goldPrimary.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [pt.goldLight, pt.goldPrimary, pt.goldLight],
              ).createShader(bounds);
            },
            child: const Text(
              'SCENARIO COMPLETE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: pt.goldPrimary.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: pt.goldPrimary.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: pt.goldPrimary),
                const SizedBox(width: 4),
                Text(
                  '+50 XP',
                  style: TextStyle(
                    color: pt.goldLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Back'),
              ),
              if (onNext != null) ...[
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next_rounded, size: 16),
                  label: const Text('Next'),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Burst of gold+accent particles that plays once when a lesson scenario
/// completes. Uses a single [AnimationController] driving a [CustomPainter]
/// so it adds ~no layout cost and respects the platform reduce-motion flag.
class _LessonCompleteConfetti extends StatefulWidget {
  const _LessonCompleteConfetti();

  @override
  State<_LessonCompleteConfetti> createState() =>
      _LessonCompleteConfettiState();
}

class _LessonCompleteConfettiState extends State<_LessonCompleteConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    final pt = context.poker;
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _LessonConfettiPainter(
          progress: _controller.value,
          palette: [
            pt.goldPrimary,
            pt.goldLight,
            pt.accent,
            pt.seatActiveBorder,
            Colors.white,
          ],
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _LessonConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> palette;
  static const _particleCount = 36;

  _LessonConfettiPainter({required this.progress, required this.palette});

  @override
  void paint(Canvas canvas, Size size) {
    final rand = math.Random(17);
    final center = Offset(size.width / 2, size.height * 0.55);
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _particleCount; i++) {
      final angle = rand.nextDouble() * math.pi * 2;
      final speed = 80 + rand.nextDouble() * 180;
      // Ease-out trajectory with a bit of gravity after apex.
      final t = progress;
      final dx = math.cos(angle) * speed * t;
      final dy = math.sin(angle) * speed * t + 260 * t * t;
      final pos = center + Offset(dx, dy);
      final color = palette[i % palette.length];
      final fade = (1 - t).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: fade);
      final r = 3.0 + rand.nextDouble() * 2.5;
      // Rotate each particle as it flies for extra life.
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + t * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: r * 2, height: r),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _LessonConfettiPainter old) =>
      old.progress != progress;
}
