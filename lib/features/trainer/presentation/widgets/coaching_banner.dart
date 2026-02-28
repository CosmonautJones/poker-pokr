import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/lesson.dart';

/// A coaching tip banner shown during lesson play.
///
/// Displays the current coaching tip with title, body, and optional stat.
/// Can be collapsed/expanded by tapping.
class CoachingBanner extends StatefulWidget {
  final CoachingTip? tip;

  const CoachingBanner({super.key, required this.tip});

  @override
  State<CoachingBanner> createState() => _CoachingBannerState();
}

class _CoachingBannerState extends State<CoachingBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();
  }

  @override
  void didUpdateWidget(CoachingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when a new tip arrives.
    if (widget.tip != oldWidget.tip && widget.tip != null) {
      _expanded = true;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    if (tip == null) return const SizedBox.shrink();

    final pt = context.poker;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          // Subtle border shimmer sweep
          final shimmerPos = _shimmerController.value * 3 - 1;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: _expanded ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: pt.tooltipBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pt.goldPrimary.withValues(alpha: 0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  pt.goldLight.withValues(alpha: 0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
                begin: Alignment(shimmerPos - 0.5, 0),
                end: Alignment(shimmerPos + 0.5, 0),
              ),
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.school_rounded,
                  color: pt.goldPrimary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tip.title,
                    style: TextStyle(
                      color: pt.goldLight,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (tip.stat != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: pt.goldPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tip.stat!,
                      style: TextStyle(
                        color: pt.goldPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: const Duration(milliseconds: 300))
                      .scaleXY(
                        begin: 0.8,
                        end: 1.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                      ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.expand_more,
                    color: pt.textMuted,
                    size: 18,
                  ),
                ),
              ],
            ),
            // Body (expanded) with fade-in
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  tip.body,
                  style: TextStyle(
                    color: pt.textMuted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _expanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
              sizeCurve: Curves.easeOut,
              firstCurve: Curves.easeOut,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: PokerAnimations.kCoachingEntrance)
        .scaleXY(
          begin: 0.95,
          end: 1.0,
          duration: PokerAnimations.kCoachingEntrance,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          duration: PokerAnimations.kCoachingEntrance,
          curve: Curves.easeOutCubic,
        );
  }
}
