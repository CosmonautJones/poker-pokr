import 'package:flutter/material.dart';
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

class _CoachingBannerState extends State<CoachingBanner> {
  bool _expanded = true;

  @override
  void didUpdateWidget(CoachingBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-expand when a new tip arrives.
    if (widget.tip != oldWidget.tip && widget.tip != null) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = widget.tip;
    if (tip == null) return const SizedBox.shrink();

    final pt = context.poker;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
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
                  ),
                const SizedBox(width: 4),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: pt.textMuted,
                  size: 18,
                ),
              ],
            ),
            // Body (expanded)
            if (_expanded) ...[
              const SizedBox(height: 6),
              Text(
                tip.body,
                style: TextStyle(
                  color: pt.textMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
