import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/features/trainer/providers/equity_provider.dart';
import 'package:poker_trainer/poker/engine/equity_calculator.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

/// Whether the equity display labels are collapsed (just bar, no names/%).
final _equityCollapsedProvider = StateProvider<bool>((ref) => false);

/// Compact equity bar showing win percentages for all active players.
///
/// Sits between the table and the context strip. Shows a segmented
/// horizontal bar with each player's equity as a proportional section,
/// plus labels. Tap to collapse labels and save vertical space.
class EquityDisplay extends ConsumerWidget {
  final GameState gameState;

  const EquityDisplay({super.key, required this.gameState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEquity = ref.watch(equityProvider(gameState));

    return asyncEquity.when(
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return _EquityBar(result: result, gameState: gameState);
      },
      loading: () => _LoadingIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _LoadingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: pt.surfaceOverlay,
        border: Border(
          top: BorderSide(
            color: pt.borderSubtle.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: pt.accent.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Calculating equity...',
            style: TextStyle(
              fontSize: 10,
              color: pt.textMuted.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _EquityBar extends ConsumerWidget {
  final EquityResult result;
  final GameState gameState;

  const _EquityBar({required this.result, required this.gameState});

  static const _playerColors = [
    Color(0xFF4FC3F7), // light blue
    Color(0xFFEF5350), // red
    Color(0xFF66BB6A), // green
    Color(0xFFFFCA28), // amber
    Color(0xFFAB47BC), // purple
    Color(0xFFFF7043), // deep orange
    Color(0xFF26C6DA), // cyan
    Color(0xFF8D6E63), // brown
    Color(0xFFEC407A), // pink
    Color(0xFF78909C), // blue grey
  ];

  Color _colorForPlayer(int index) {
    return _playerColors[index % _playerColors.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pt = context.poker;
    final collapsed = ref.watch(_equityCollapsedProvider);

    // Sort equities by player index for consistent display.
    final equities = List<PlayerEquity>.from(result.playerEquities)
      ..sort((a, b) => a.playerIndex.compareTo(b.playerIndex));

    if (equities.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        ref.read(_equityCollapsedProvider.notifier).state = !collapsed;
      },
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Player labels with percentages (collapsible)
            AnimatedCrossFade(
              firstChild: Row(
                children: [
                  for (int i = 0; i < equities.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _PlayerEquityLabel(
                      name: gameState.players[equities[i].playerIndex].name,
                      equity: equities[i],
                      color: _colorForPlayer(equities[i].playerIndex),
                      isLeading: equities[i].equity ==
                          equities.map((e) => e.equity).reduce(
                              (a, b) => a > b ? a : b),
                    ),
                  ],
                ],
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: collapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
            if (!collapsed) const SizedBox(height: 2),
            // Segmented equity bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: SizedBox(
                height: 6,
                child: Row(
                  children: [
                    for (int i = 0; i < equities.length; i++)
                      Expanded(
                        flex: (equities[i].equity * 1000).round().clamp(1, 1000),
                        child: Container(
                          color: _colorForPlayer(equities[i].playerIndex),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: const Duration(milliseconds: 200))
        .slideY(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
  }
}

class _PlayerEquityLabel extends StatelessWidget {
  final String name;
  final PlayerEquity equity;
  final Color color;
  final bool isLeading;

  const _PlayerEquityLabel({
    required this.name,
    required this.equity,
    required this.color,
    required this.isLeading,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              name,
              style: TextStyle(
                fontSize: 9.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '${equity.equityPercent}%',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isLeading ? FontWeight.w700 : FontWeight.w500,
              color: isLeading
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
