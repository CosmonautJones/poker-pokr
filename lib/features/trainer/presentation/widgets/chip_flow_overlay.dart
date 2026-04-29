import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/motion.dart';
import 'package:poker_trainer/poker/models/game_state.dart';

/// Animation layer that watches `currentBet` deltas on each player and
/// animates 1–4 small chips flying from that seat to the pot.
///
/// The widget tracks the previous [GameState] internally so callers don't
/// have to thread bet diffs themselves; just rebuild this layer whenever
/// the table state changes.
class ChipFlowLayer extends StatefulWidget {
  final GameState gameState;
  final List<Offset> seatCenters;
  final Offset potCenter;

  const ChipFlowLayer({
    super.key,
    required this.gameState,
    required this.seatCenters,
    required this.potCenter,
  });

  @override
  State<ChipFlowLayer> createState() => _ChipFlowLayerState();
}

class _ChipFlowLayerState extends State<ChipFlowLayer>
    with TickerProviderStateMixin {
  /// Per-player snapshot of the last `currentBet` we observed. Used to
  /// detect bet increases and avoid re-spawning chips when the pot
  /// settles (currentBet can be reset to zero on street change).
  late List<double> _lastBets;

  /// Active chip animations. Each chip drives its own
  /// [AnimationController] so they can stagger independently and clean
  /// themselves up when complete.
  final List<_ChipFlight> _flights = [];

  // Big-blind heuristic for sizing the chip burst. Cached from initial
  // state so we don't recompute every diff.
  double _bigBlind = 1.0;

  @override
  void initState() {
    super.initState();
    _lastBets = [for (final p in widget.gameState.players) p.currentBet];
    _bigBlind = math.max(1.0, widget.gameState.bigBlind);
  }

  @override
  void didUpdateWidget(covariant ChipFlowLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ng = widget.gameState;
    final prev = _lastBets;
    final next = [for (final p in ng.players) p.currentBet];

    // Adjust length if player count changed (defensive — shouldn't happen
    // mid-hand but keeps this layer robust).
    if (prev.length != next.length) {
      _lastBets = next;
      return;
    }

    _bigBlind = math.max(1.0, ng.bigBlind);
    final animate = Motion.shouldAnimate(context);

    for (int i = 0; i < next.length; i++) {
      final delta = next[i] - prev[i];
      // Only animate increases. Decreases happen on street rollover when
      // currentBet resets to 0 — those should not trigger flights.
      if (delta > 0.001 && animate && i < widget.seatCenters.length) {
        _spawnFlight(i, delta);
      }
    }
    _lastBets = next;
  }

  void _spawnFlight(int playerIndex, double delta) {
    final from = widget.seatCenters[playerIndex];
    final to = widget.potCenter;
    final chipCount = _chipCountForBet(delta);

    for (int c = 0; c < chipCount; c++) {
      final controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 460),
      );
      final flight = _ChipFlight(
        controller: controller,
        from: from,
        to: to,
        // Stagger chips slightly so they don't read as one big blob.
        delayMs: c * 70,
        chipIndex: c,
        // Bezier control point offset perpendicular to the segment so
        // chips arc rather than streak in a straight line.
        arcSign: c.isEven ? 1.0 : -1.0,
      );
      _flights.add(flight);

      Future<void>.delayed(Duration(milliseconds: flight.delayMs), () {
        if (!mounted) return;
        controller.forward();
      });

      controller.addStatusListener((status) {
        if (status != AnimationStatus.completed) return;
        if (flight.disposed) return;
        flight.disposed = true;
        controller.dispose();
        if (!mounted) {
          // Widget already torn down; dispose() won't re-dispose because
          // [flight.disposed] is set.
          return;
        }
        setState(() {
          _flights.remove(flight);
        });
      });
    }
    // didUpdateWidget already triggers a rebuild; the new entries in
    // _flights will be picked up by the next build pass.
  }

  /// 1–4 chips depending on the bet delta relative to the big blind.
  int _chipCountForBet(double delta) {
    final bb = delta / _bigBlind;
    if (bb >= 20) return 4;
    if (bb >= 6) return 3;
    if (bb >= 1) return 2;
    return 1;
  }

  @override
  void dispose() {
    for (final f in _flights) {
      if (f.disposed) continue;
      f.disposed = true;
      f.controller.dispose();
    }
    _flights.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_flights.isEmpty) {
      // Always non-hit-testing so the layer never blocks seat gestures.
      return const IgnorePointer(child: SizedBox.shrink());
    }
    final pt = context.poker;
    final palette = <Color>[pt.chipRed, pt.chipBlue, pt.chipGreen, pt.chipWhite];
    return IgnorePointer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final flight in _flights)
            AnimatedBuilder(
              animation: flight.controller,
              builder: (context, _) {
                final t = flight.controller.value;
                final eased = Curves.easeInOutCubic.transform(t);
                final pos = _bezier(flight.from, flight.to, eased,
                    flight.arcSign);
                final fade = t < 0.85 ? 1.0 : (1.0 - t) / 0.15;
                final rotation = (t * math.pi * 2) * (flight.arcSign);
                return Positioned(
                  left: pos.dx - 8,
                  top: pos.dy - 8,
                  child: Opacity(
                    opacity: fade.clamp(0.0, 1.0),
                    child: Transform.rotate(
                      angle: rotation,
                      child: _ChipDot(
                        color: palette[flight.chipIndex % palette.length],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  /// Quadratic Bezier from [from] to [to] with a control point offset
  /// perpendicular to the segment. [sign] flips the arc direction.
  Offset _bezier(Offset from, Offset to, double t, double sign) {
    final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = len == 0 ? 0.0 : -dy / len;
    final ny = len == 0 ? 0.0 : dx / len;
    final arc = math.min(60.0, len * 0.25);
    final ctrl = Offset(mid.dx + nx * arc * sign, mid.dy + ny * arc * sign);
    final mt = 1 - t;
    final x = mt * mt * from.dx + 2 * mt * t * ctrl.dx + t * t * to.dx;
    final y = mt * mt * from.dy + 2 * mt * t * ctrl.dy + t * t * to.dy;
    return Offset(x, y);
  }
}

class _ChipFlight {
  final AnimationController controller;
  final Offset from;
  final Offset to;
  final int delayMs;
  final int chipIndex;
  final double arcSign;

  /// Set once whichever path (status listener or widget dispose) tears the
  /// controller down first, so the other path can skip a double-dispose.
  bool disposed = false;

  _ChipFlight({
    required this.controller,
    required this.from,
    required this.to,
    required this.delayMs,
    required this.chipIndex,
    required this.arcSign,
  });
}

class _ChipDot extends StatelessWidget {
  final Color color;
  const _ChipDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 3,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
    );
  }
}
