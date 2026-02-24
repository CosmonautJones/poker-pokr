import 'package:flutter/material.dart';
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
    final ctx = context_;

    // Extract the base position label (e.g. "BTN" from "BTN (SB)").
    final posAbbrev = ctx.positionLabel.split(' ').first;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        border: Border(
          top: BorderSide(color: Colors.grey.shade800, width: 0.5),
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Situation chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _ContextChip(
                  label: ctx.positionLabel,
                  color: _positionColor(ctx.positionCategory),
                  glossaryTerm: posAbbrev,
                ),
                if (ctx.potOddsDisplay != null)
                  _ContextChip(
                    label: 'Pot Odds',
                    value: ctx.potOddsDisplay!,
                    color: Colors.amber.shade300,
                    glossaryTerm: 'Pot Odds',
                  ),
                _ContextChip(
                  label: 'SPR',
                  value: ctx.stackToPotRatio.toStringAsFixed(1),
                  color: ctx.stackToPotRatio < 4
                      ? Colors.orange.shade300
                      : null,
                  glossaryTerm: 'SPR',
                ),
                _ContextChip(
                  label: '${ctx.playersInHand} in hand',
                ),
                _ContextChip(
                  label: ctx.playersYetToAct > 0
                      ? '${ctx.playersYetToAct} behind'
                      : 'Last to act',
                ),
              ],
            ),
          ),
          // Row 2: Last action or street summary
          if (ctx.streetSummary != null) ...[
            const SizedBox(height: 4),
            _StreetSummaryRow(summary: ctx.streetSummary!),
          ] else if (ctx.lastAction != null) ...[
            const SizedBox(height: 4),
            _ActionExplanationRow(explanation: ctx.lastAction!),
          ],
        ],
      ),
    );
  }

  static Color _positionColor(String category) {
    return switch (category) {
      'early' => Colors.red.shade300,
      'middle' => Colors.orange.shade300,
      'late' => Colors.green.shade300,
      'blinds' => Colors.blue.shade300,
      _ => Colors.grey.shade300,
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

  const _ContextChip({
    required this.label,
    this.value,
    this.color,
    this.glossaryTerm,
  });

  @override
  Widget build(BuildContext context) {
    final entry = glossaryTerm != null
        ? PokerGlossary.lookup(glossaryTerm!)
        : null;
    final isTappable = entry != null;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade700, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (color != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            value != null ? '$label: $value' : label,
            style: TextStyle(
              fontSize: 11,
              color: color ?? Colors.white70,
              fontWeight: FontWeight.w500,
              decoration:
                  isTappable ? TextDecoration.underline : null,
              decorationColor: (color ?? Colors.white70).withValues(alpha: 0.4),
              decorationStyle: TextDecorationStyle.dotted,
            ),
          ),
          if (isTappable) ...[
            const SizedBox(width: 3),
            Icon(
              Icons.info_outline_rounded,
              size: 10,
              color: (color ?? Colors.white70).withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );

    if (!isTappable) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: chip,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
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

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
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
    final screenWidth = MediaQuery.of(context).size.width;
    const tooltipWidth = 260.0;

    // Position above the chip, centered horizontally.
    final centerX =
        widget.anchorOffset.dx + widget.anchorSize.width / 2;
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
          child: FadeTransition(
            opacity: _opacity,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: tooltipWidth,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade700.withValues(alpha: 0.4),
                  ),
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
                            color: Colors.amber.shade200,
                          ),
                        ),
                        if (widget.entry.term != widget.entry.abbreviation) ...[
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

/// Row 2 variant: explains the last action with a colored dot.
class _ActionExplanationRow extends StatelessWidget {
  final ActionExplanation explanation;

  const _ActionExplanationRow({required this.explanation});

  @override
  Widget build(BuildContext context) {
    // Infer action type color from description keywords
    final color = _inferActionColor(explanation.description);
    final parts = <String>[explanation.description];
    parts.add(explanation.mechanical);
    if (explanation.sizing != null) parts.add(explanation.sizing!);
    parts.add(explanation.stateChange);

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            parts.join(' · '),
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.6),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static Color _inferActionColor(String description) {
    final lower = description.toLowerCase();
    if (lower.contains('folds')) return Colors.grey;
    if (lower.contains('checks')) return Colors.blueGrey.shade300;
    if (lower.contains('calls')) return Colors.green.shade300;
    if (lower.contains('all-in')) return Colors.deepOrange.shade300;
    if (lower.contains('raises') || lower.contains('bets')) {
      return Colors.amber.shade300;
    }
    return Colors.white70;
  }
}

/// Row 2 variant: street transition summary.
class _StreetSummaryRow extends StatelessWidget {
  final StreetSummary summary;

  const _StreetSummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '\u2500\u2500 ${summary.completedStreet} \u2500\u2500 ${summary.summary}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
