import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/providers/auto_play_provider.dart';

/// Horizontal control strip shown during auto-play, replacing the ActionBar.
class AutoPlayControls extends StatelessWidget {
  final AutoPlayState autoPlayState;
  final VoidCallback onPauseResume;
  final VoidCallback onStop;
  final ValueChanged<AutoPlaySpeed> onSpeedChanged;

  const AutoPlayControls({
    super.key,
    required this.autoPlayState,
    required this.onPauseResume,
    required this.onStop,
    required this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isPaused = autoPlayState.isPaused;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border(
          top: BorderSide(color: pt.borderSubtle, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Auto-play indicator
            Icon(
              Icons.smart_toy_outlined,
              color: pt.accent,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isPaused ? 'Paused' : 'Auto-Playing...',
              style: TextStyle(
                color: isPaused ? pt.textMuted : pt.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '(${autoPlayState.actionsPlayed} actions)',
              style: TextStyle(color: pt.textMuted, fontSize: 12),
            ),
            const Spacer(),
            // Speed toggle
            _SpeedChip(
              currentSpeed: autoPlayState.speed,
              onChanged: onSpeedChanged,
            ),
            const SizedBox(width: 8),
            // Pause/Resume
            IconButton(
              onPressed: onPauseResume,
              icon: Icon(
                isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                size: 24,
              ),
              style: IconButton.styleFrom(
                backgroundColor: pt.accent.withValues(alpha: 0.15),
                foregroundColor: pt.accent,
              ),
              tooltip: isPaused ? 'Resume' : 'Pause',
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 4),
            // Stop
            IconButton(
              onPressed: onStop,
              icon: const Icon(Icons.stop_rounded, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: pt.actionFold.withValues(alpha: 0.15),
                foregroundColor: pt.actionFold,
              ),
              tooltip: 'Stop',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeedChip extends StatelessWidget {
  final AutoPlaySpeed currentSpeed;
  final ValueChanged<AutoPlaySpeed> onChanged;

  const _SpeedChip({required this.currentSpeed, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return PopupMenuButton<AutoPlaySpeed>(
      onSelected: onChanged,
      tooltip: 'Playback speed',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: pt.borderSubtle.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.speed_rounded, size: 14, color: pt.textMuted),
            const SizedBox(width: 4),
            Text(
              currentSpeed.label,
              style: TextStyle(color: pt.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
      itemBuilder: (_) => AutoPlaySpeed.values.map((speed) {
        return PopupMenuItem(
          value: speed,
          child: Row(
            children: [
              if (speed == currentSpeed)
                Icon(Icons.check_rounded, size: 16, color: pt.accent)
              else
                const SizedBox(width: 16),
              const SizedBox(width: 8),
              Text(speed.label),
            ],
          ),
        );
      }).toList(),
    );
  }
}
