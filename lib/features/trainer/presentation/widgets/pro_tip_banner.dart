import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/pro_tips.dart';

/// A collapsible banner that shows a contextual pro tip.
///
/// Sits between the context strip and the action bar. Tap to expand/collapse.
class ProTipBanner extends StatefulWidget {
  final ProTip? tip;

  const ProTipBanner({super.key, required this.tip});

  @override
  State<ProTipBanner> createState() => _ProTipBannerState();
}

class _ProTipBannerState extends State<ProTipBanner>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ProTipBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Collapse when the tip changes so the user sees the new title.
    if (widget.tip?.title != oldWidget.tip?.title) {
      _expanded = false;
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final tip = widget.tip;
    if (tip == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: _toggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              pt.actionBet.withValues(alpha: 0.25),
              Colors.transparent,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border(
            bottom: BorderSide(
              color: pt.actionBet.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header row — always visible
            Row(
              children: [
                Icon(
                  Icons.lightbulb_rounded,
                  size: 14,
                  color: pt.accent,
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .scaleXY(
                      begin: 1.0,
                      end: 1.15,
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeInOut,
                    ),
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: pt.actionBet.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tip.category,
                    style: TextStyle(
                      fontSize: 9,
                      color: pt.accentMuted,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tip.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: pt.accentMuted,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: pt.accent.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            // Body — animated expand/collapse
            ClipRect(
              child: AnimatedBuilder(
                animation: _heightFactor,
                builder: (context, child) => Align(
                  alignment: Alignment.topLeft,
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, left: 20),
                  child: Text(
                    tip.body,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: PokerAnimations.kTipEntrance)
        .slideY(
          begin: -0.15,
          end: 0,
          duration: PokerAnimations.kTipEntrance,
          curve: PokerAnimations.tipEntranceCurve,
        );
  }
}
