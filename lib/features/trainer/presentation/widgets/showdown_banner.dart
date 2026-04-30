import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/game_state.dart';
import 'package:poker_trainer/poker/models/street.dart';

/// Cinematic top-of-table reveal of the winning hand at showdown.
///
/// Slides down + scales in with a gold gradient title. Self-contained: shows
/// only when the game has reached [Street.showdown] with a populated
/// `handDescriptions` and known winners. For fold-out wins (no showdown) this
/// returns an empty widget — the bottom overlay is sufficient there.
class ShowdownBanner extends StatefulWidget {
  final GameState gameState;

  const ShowdownBanner({super.key, required this.gameState});

  @override
  State<ShowdownBanner> createState() => _ShowdownBannerState();
}

class _ShowdownBannerState extends State<ShowdownBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 520),
      vsync: this,
    )..forward();
  }

  @override
  void didUpdateWidget(ShowdownBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-trigger the reveal when the showdown context meaningfully changes
    // (e.g. user undoes out of showdown then re-enters, or switches branches).
    final prevSig = _signature(oldWidget.gameState);
    final nextSig = _signature(widget.gameState);
    if (prevSig != nextSig) {
      _ctrl
        ..reset()
        ..forward();
    }
  }

  String _signature(GameState gs) {
    final winners = gs.winnerIndices?.join(',') ?? '';
    final descriptions = gs.handDescriptions.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    return '${gs.street}|$winners|$descriptions';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _winningHandText() {
    final gs = widget.gameState;
    if (gs.street != Street.showdown) return null;
    if (gs.winnerIndices == null || gs.winnerIndices!.isEmpty) return null;
    if (gs.handDescriptions.isEmpty) return null;
    final descriptions = gs.winnerIndices!
        .where((i) => gs.handDescriptions.containsKey(i))
        .map((i) => gs.handDescriptions[i]!)
        .toSet()
        .toList();
    if (descriptions.isEmpty) return null;
    return descriptions.join(' / ');
  }

  String? _winnerNameText() {
    final gs = widget.gameState;
    if (gs.winnerIndices == null || gs.winnerIndices!.isEmpty) return null;
    return gs.winnerIndices!.map((i) => gs.players[i].name).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final hand = _winningHandText();
    if (hand == null) return const SizedBox.shrink();
    final winners = _winnerNameText();

    final slide = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    return SlideTransition(
      position: slide,
      child: FadeTransition(
        opacity: _ctrl,
        child: ScaleTransition(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: pt.goldPrimary.withValues(alpha: 0.55),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: pt.goldPrimary.withValues(alpha: 0.20),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [pt.goldLight, pt.goldPrimary, pt.goldLight],
                  ).createShader(bounds),
                  child: Text(
                    hand.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (winners != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Winner: $winners',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
