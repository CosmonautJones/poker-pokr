import 'package:flutter/material.dart';
import 'package:poker_trainer/features/trainer/domain/educational_context.dart';

/// Educational context strip shown between the poker table and action bar.
///
/// Displays situation chips (position, pot odds, SPR, players) on row 1,
/// and a last-action explanation or street summary on row 2.
class ContextStrip extends StatelessWidget {
  final EducationalContext context_;

  const ContextStrip({super.key, required this.context_});

  @override
  Widget build(BuildContext context) {
    final ctx = context_;
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
                ),
                if (ctx.potOddsDisplay != null)
                  _ContextChip(
                    label: 'Pot Odds',
                    value: ctx.potOddsDisplay!,
                    color: Colors.amber.shade300,
                  ),
                _ContextChip(
                  label: 'SPR',
                  value: ctx.stackToPotRatio.toStringAsFixed(1),
                  color: ctx.stackToPotRatio < 4
                      ? Colors.orange.shade300
                      : null,
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
class _ContextChip extends StatelessWidget {
  final String label;
  final String? value;
  final Color? color;

  const _ContextChip({
    required this.label,
    this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
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
              ),
            ),
          ],
        ),
      ),
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
