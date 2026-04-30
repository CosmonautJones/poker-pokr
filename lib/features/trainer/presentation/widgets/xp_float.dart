import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

/// Small "+XP" pill that floats up and fades. Used at hand completion to
/// reinforce the reward feedback loop. One-shot — disposes itself when the
/// animation finishes (parent re-mounts via a Key bound to the hand id /
/// completion event to retrigger).
class XpFloat extends StatefulWidget {
  final int xpDelta;
  final String? sublabel;

  const XpFloat({super.key, required this.xpDelta, this.sublabel});

  @override
  State<XpFloat> createState() => _XpFloatState();
}

class _XpFloatState extends State<XpFloat>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final dy = -36.0 * Curves.easeOut.transform(t);
        final opacity = t < 0.15
            ? (t / 0.15).clamp(0.0, 1.0)
            : (1.0 - ((t - 0.6) / 0.4)).clamp(0.0, 1.0);
        final scale = 0.85 + 0.15 * Curves.easeOutBack.transform(t);
        return IgnorePointer(
          ignoring: true,
          child: Transform.translate(
            offset: Offset(0, dy),
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: pt.goldPrimary.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: pt.goldPrimary.withValues(alpha: 0.35),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 12,
                        color: pt.goldPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${widget.xpDelta} XP',
                        style: TextStyle(
                          color: pt.goldLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (widget.sublabel != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          widget.sublabel!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
