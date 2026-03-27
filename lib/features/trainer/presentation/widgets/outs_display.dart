import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/engine/outs_calculator.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// Interactive outs training widget.
///
/// Shows each non-folded player's hand. The user taps to guess the number of
/// outs, then the widget reveals the correct answer with color feedback.
class OutsDisplay extends StatefulWidget {
  final GameState gameState;

  const OutsDisplay({super.key, required this.gameState});

  @override
  State<OutsDisplay> createState() => _OutsDisplayState();
}

class _OutsDisplayState extends State<OutsDisplay> {
  /// Per-player guess state. null = not guessed yet.
  final Map<int, int?> _guesses = {};

  /// Per-player computed outs (lazy-calculated).
  final Map<int, OutsResult> _results = {};

  /// Whether the outs panel is expanded.
  bool _expanded = false;

  @override
  void didUpdateWidget(OutsDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset state when the board changes.
    if (oldWidget.gameState.communityCards.length !=
            widget.gameState.communityCards.length ||
        oldWidget.gameState.street != widget.gameState.street) {
      _guesses.clear();
      _results.clear();
    }
  }

  OutsResult _getResult(int playerIndex) {
    return _results.putIfAbsent(playerIndex, () {
      final gs = widget.gameState;
      final player = gs.players[playerIndex];
      // Collect dead cards: other players' known hole cards.
      final deadCards = gs.players
          .where((p) => p.index != playerIndex && !p.isFolded)
          .expand((p) => p.holeCards)
          .toList();
      return OutsCalculator.calculate(
        holeCards: player.holeCards,
        communityCards: gs.communityCards,
        gameType: gs.gameType,
        deadCards: deadCards,
      );
    });
  }

  void _showGuessPicker(BuildContext context, int playerIndex) {
    final pt = context.poker;
    int guess = _guesses[playerIndex] ?? 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'How many outs does ${widget.gameState.players[playerIndex].name} have?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: pt.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: guess > 0
                            ? () => setSheetState(() => guess--)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '$guess',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: pt.goldPrimary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: guess < 47
                            ? () => setSheetState(() => guess++)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick-select common outs values.
                  Wrap(
                    spacing: 8,
                    children: [0, 2, 4, 6, 8, 9, 12, 15].map((v) {
                      return ChoiceChip(
                        label: Text('$v'),
                        selected: guess == v,
                        onSelected: (_) => setSheetState(() => guess = v),
                        visualDensity: VisualDensity.compact,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(ctx).pop(guess);
                    },
                    child: const Text('Submit Guess'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((result) {
      if (result != null && mounted) {
        setState(() {
          _guesses[playerIndex] = result as int;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gameState;
    final pt = context.poker;

    // Only show on flop and turn.
    if (gs.street != Street.flop && gs.street != Street.turn) {
      return const SizedBox.shrink();
    }

    final activePlayers =
        gs.players.where((p) => !p.isFolded && p.holeCards.isNotEmpty).toList();

    if (activePlayers.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: pt.surfaceOverlay,
          border: Border(
            top: BorderSide(
              color: pt.borderSubtle.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Icon(
                  Icons.casino_outlined,
                  size: 14,
                  color: pt.accent.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Outs Training',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: pt.textMuted.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _expanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 14,
                  color: pt.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 4),
              for (final player in activePlayers)
                _PlayerOutsRow(
                  playerName: player.name,
                  playerIndex: player.index,
                  guess: _guesses[player.index],
                  result: _guesses.containsKey(player.index)
                      ? _getResult(player.index)
                      : null,
                  onTap: () => _showGuessPicker(context, player.index),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerOutsRow extends StatelessWidget {
  final String playerName;
  final int playerIndex;
  final int? guess;
  final OutsResult? result;
  final VoidCallback onTap;

  const _PlayerOutsRow({
    required this.playerName,
    required this.playerIndex,
    required this.guess,
    required this.result,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final hasGuessed = guess != null;
    final isCorrect = hasGuessed && result != null && guess == result!.outs;
    final isClose =
        hasGuessed && result != null && (guess! - result!.outs).abs() <= 2;

    Color statusColor;
    if (!hasGuessed) {
      statusColor = pt.textMuted.withValues(alpha: 0.5);
    } else if (isCorrect) {
      statusColor = const Color(0xFF66BB6A); // green
    } else if (isClose) {
      statusColor = const Color(0xFFFFCA28); // amber
    } else {
      statusColor = const Color(0xFFEF5350); // red
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            // Player name
            SizedBox(
              width: 70,
              child: Text(
                playerName,
                style: TextStyle(
                  fontSize: 11,
                  color: pt.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Guess / result display
            if (!hasGuessed)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: pt.accent.withValues(alpha: 0.3),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Tap to guess outs',
                  style: TextStyle(
                    fontSize: 10,
                    color: pt.accent.withValues(alpha: 0.7),
                  ),
                ),
              )
            else ...[
              // Show guess
              Text(
                'Guess: $guess',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 8),
              // Show correct answer
              Text(
                'Actual: ${result?.outs ?? "?"}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                isCorrect
                    ? Icons.check_circle
                    : isClose
                        ? Icons.remove_circle
                        : Icons.cancel,
                size: 14,
                color: statusColor,
              ),
            ],
            const Spacer(),
            // Draw types (shown after guessing)
            if (hasGuessed && result != null && result!.drawTypes.isNotEmpty)
              Flexible(
                child: Text(
                  result!.drawTypes.join(', '),
                  style: TextStyle(
                    fontSize: 9,
                    color: pt.textMuted.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
