import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/domain/educational_context.dart';
import 'package:poker_trainer/features/trainer/domain/poker_glossary.dart';
import 'package:poker_trainer/features/trainer/presentation/widgets/poker_glossary_sheet.dart';

/// Educational context strip shown between the poker table and action bar.
///
/// Displays situation chips (position, pot odds, SPR, players) on row 1,
/// and a last-action explanation or street summary on row 2.
/// Tapping a chip with a known term opens the glossary highlighted to that term.
class ContextStrip extends StatelessWidget {
  final EducationalContext context_;

  const ContextStrip({super.key, required this.context_});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final ctx = context_;

    // Extract the base position label (e.g. "BTN" from "BTN (SB)").
    final posAbbrev = ctx.positionLabel.split(' ').first;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: pt.surfaceOverlay,
        border: Border(
          top: BorderSide(
              color: pt.borderSubtle.withValues(alpha: 0.3), width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Situation chips - compact single row with staggered entrance
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ContextChip(
                  label: ctx.positionLabel,
                  color: _positionColor(context, ctx.positionCategory),
                  glossaryTerm: posAbbrev,
                  staggerIndex: 0,
                ),
                if (ctx.potOddsDisplay != null)
                  _ContextChip(
                    label: 'Odds',
                    value: ctx.potOddsDisplay!,
                    color: pt.accent,
                    glossaryTerm: 'Pot Odds',
                    staggerIndex: 1,
                  ),
                _ContextChip(
                  label: 'SPR',
                  value: ctx.stackToPotRatio.toStringAsFixed(1),
                  color: ctx.stackToPotRatio < 4 ? pt.positionMiddle : null,
                  glossaryTerm: 'SPR',
                  staggerIndex: 2,
                ),
                _ContextChip(
                  label: '${ctx.playersInHand} in',
                  staggerIndex: 3,
                ),
                if (ctx.playersYetToAct > 0)
                  _ContextChip(
                    label: '${ctx.playersYetToAct} behind',
                    staggerIndex: 4,
                  ),
              ],
            ),
          ),
          // Row 2: Last action or street summary - single line
          if (ctx.streetSummary != null) ...[
            const SizedBox(height: 3),
            _StreetSummaryRow(summary: ctx.streetSummary!),
          ] else if (ctx.lastAction != null) ...[
            const SizedBox(height: 3),
            _ActionExplanationRow(explanation: ctx.lastAction!),
          ],
        ],
      ),
    );
  }

  static Color _positionColor(BuildContext context, String category) {
    final pt = context.poker;
    return switch (category) {
      'early' => pt.positionEarly,
      'middle' => pt.positionMiddle,
      'late' => pt.positionLate,
      'blinds' => pt.positionBlinds,
      _ => pt.textMuted,
    };
  }
}

/// A small rounded chip showing a label and optional value.
/// When [glossaryTerm] is set, tapping the chip shows an inline tooltip
/// with the definition, and long-pressing opens the full glossary.
class _ContextChip extends StatelessWidget {
  final String label;
  final String? value;
  final Color? color;
  final String? glossaryTerm;
  final int staggerIndex;

  const _ContextChip({
    required this.label,
    this.value,
    this.color,
    this.glossaryTerm,
    this.staggerIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final entry =
        glossaryTerm != null ? PokerGlossary.lookup(glossaryTerm!) : null;
    final isTappable = entry != null;
    final chipColor = color ?? pt.textMuted;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            value != null ? '$label $value' : label,
            style: TextStyle(
              fontSize: 10.5,
              color: chipColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(
            milliseconds: 40 * staggerIndex,
          ),
          duration: PokerAnimations.kContextChipEntrance,
        )
        .scaleXY(
          begin: 0.85,
          end: 1.0,
          delay: Duration(milliseconds: 40 * staggerIndex),
          duration: PokerAnimations.kContextChipEntrance,
          curve: Curves.easeOutBack,
        );

    if (!isTappable) {
      return Padding(
        padding: const EdgeInsets.only(right: 5),
        child: chip,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: () => _showDefinitionTooltip(context, entry),
        onLongPress: () =>
            PokerGlossarySheet.show(context, highlightTerm: glossaryTerm),
        child: chip,
      ),
    );
  }

  void _showDefinitionTooltip(BuildContext context, GlossaryEntry entry) {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (ctx) => _GlossaryTooltipOverlay(
        entry: entry,
        anchorOffset: offset,
        anchorSize: size,
        onDismiss: () => overlayEntry.remove(),
      ),
    );
    overlay.insert(overlayEntry);
  }
}

/// Tooltip overlay showing a glossary definition near the tapped chip.
class _GlossaryTooltipOverlay extends StatefulWidget {
  final GlossaryEntry entry;
  final Offset anchorOffset;
  final Size anchorSize;
  final VoidCallback onDismiss;

  const _GlossaryTooltipOverlay({
    required this.entry,
    required this.anchorOffset,
    required this.anchorSize,
    required this.onDismiss,
  });

  @override
  State<_GlossaryTooltipOverlay> createState() =>
      _GlossaryTooltipOverlayState();
}

class _GlossaryTooltipOverlayState extends State<_GlossaryTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slideY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideY = Tween<double>(begin: 6.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();

    // Auto-dismiss after 4 seconds.
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final screenWidth = MediaQuery.of(context).size.width;
    const tooltipWidth = 260.0;

    // Position above the chip, centered horizontally.
    final centerX = widget.anchorOffset.dx + widget.anchorSize.width / 2;
    var left = centerX - tooltipWidth / 2;
    // Keep within screen bounds.
    left = left.clamp(8.0, screenWidth - tooltipWidth - 8);
    final bottom =
        MediaQuery.of(context).size.height - widget.anchorOffset.dy + 6;

    return Stack(
      children: [
        // Dismiss on tap anywhere.
        Positioned.fill(
          child: GestureDetector(
            onTap: _dismiss,
            behavior: HitTestBehavior.translucent,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          left: left,
          bottom: bottom,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _slideY.value),
                child: Opacity(
                  opacity: _opacity.value,
                  child: child,
                ),
              );
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: tooltipWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pt.tooltipBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: pt.tooltipBorder),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.entry.abbreviation,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: pt.accentMuted,
                          ),
                        ),
                        if (widget.entry.term !=
                            widget.entry.abbreviation) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              widget.entry.term,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.entry.definition,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Row 2 variant: explains the last action with a colored dot and slide-in.
class _ActionExplanationRow extends StatelessWidget {
  final ActionExplanation explanation;

  const _ActionExplanationRow({required this.explanation});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    // Infer action type color from description keywords
    final color = _inferActionColor(pt, explanation.description);
    final parts = <String>[explanation.description];
    parts.add(explanation.mechanical);
    if (explanation.sizing != null) parts.add(explanation.sizing!);
    parts.add(explanation.stateChange);

    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 250))
        .slideX(
          begin: -0.05,
          end: 0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
  }

  static Color _inferActionColor(PokerTheme pt, String description) {
    final lower = description.toLowerCase();
    if (lower.contains('folds')) return pt.badgeFold;
    if (lower.contains('checks')) return pt.actionCheck;
    if (lower.contains('calls')) return pt.profit;
    if (lower.contains('all-in')) return pt.actionAllIn;
    if (lower.contains('raises') || lower.contains('bets')) {
      return pt.accent;
    }
    return pt.textMuted;
  }
}

/// Row 2 variant: street transition summary with fade-in.
class _StreetSummaryRow extends StatelessWidget {
  final StreetSummary summary;

  const _StreetSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '\u2500 ${summary.completedStreet} \u2500 ${summary.summary}',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.white.withValues(alpha: 0.4),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 350))
        .slideX(
          begin: -0.03,
          end: 0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
  }
}
