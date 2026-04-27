import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/core/utils/responsive.dart';
import 'package:poker_trainer/features/learn/domain/positions.dart';

/// Visual reference of poker table positions for 6-max and 9-max.
///
/// Renders an oval table with seats arranged around it, colour-coded by
/// strategic tier. Tap a seat to expand its role description below.
class PositionChartScreen extends StatefulWidget {
  const PositionChartScreen({super.key});

  @override
  State<PositionChartScreen> createState() => _PositionChartScreenState();
}

enum _Layout { ninemax, sixmax }

class _PositionChartScreenState extends State<PositionChartScreen> {
  _Layout _layout = _Layout.sixmax;
  int _selectedIndex = 0;

  List<PokerPosition> get _positions => switch (_layout) {
        _Layout.sixmax => PokerPositions.sixmax,
        _Layout.ninemax => PokerPositions.ninemax,
      };

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final positions = _positions;
    final selected = positions[_selectedIndex.clamp(0, positions.length - 1)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Positions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/learn'),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: Responsive.hPadding(context).add(
            const EdgeInsets.only(top: 8, bottom: 24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LayoutToggle(
                layout: _layout,
                onChanged: (l) => setState(() {
                  _layout = l;
                  _selectedIndex = 0;
                }),
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: 1.25,
                child: _TableDiagram(
                  positions: positions,
                  selectedIndex:
                      _selectedIndex.clamp(0, positions.length - 1),
                  onSelect: (i) => setState(() => _selectedIndex = i),
                ),
              )
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .scaleXY(begin: 0.95, end: 1, duration: 320.ms),
              const SizedBox(height: 16),
              _PositionDetailCard(position: selected),
              const SizedBox(height: 16),
              Text(
                'Tier legend',
                style: textTheme.labelLarge?.copyWith(
                  color: pt.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              const _TierLegend(),
            ],
          ),
        ),
      ),
    );
  }
}

class _LayoutToggle extends StatelessWidget {
  final _Layout layout;
  final ValueChanged<_Layout> onChanged;

  const _LayoutToggle({required this.layout, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Layout>(
      segments: const [
        ButtonSegment(value: _Layout.sixmax, label: Text('6-max')),
        ButtonSegment(value: _Layout.ninemax, label: Text('9-max')),
      ],
      selected: {layout},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class _TableDiagram extends StatelessWidget {
  final List<PokerPosition> positions;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _TableDiagram({
    required this.positions,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cx = w / 2;
        final cy = h / 2;
        const seatSize = 52.0;
        // Seat orbit radii, inset so seats stay fully inside the box.
        final orbitRx = (w - seatSize) / 2 - 4;
        final orbitRy = (h - seatSize) / 2 - 4;
        // Table felt radii — sit just inside the seat orbit so seats
        // appear to straddle the rail.
        final rx = orbitRx * 0.78;
        final ry = orbitRy * 0.78;

        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Felt
            Center(
              child: Container(
                width: rx * 2,
                height: ry * 2,
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  borderRadius: BorderRadius.all(Radius.elliptical(rx, ry)),
                  gradient: RadialGradient(
                    colors: [pt.feltHighlight, pt.feltCenter, pt.feltEdge],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  border: Border.all(
                    color: pt.tableBorder,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  'BTN acts last',
                  style: TextStyle(
                    color: pt.goldPrimary.withValues(alpha: 0.55),
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // Seats on orbit
            for (var i = 0; i < positions.length; i++)
              Positioned(
                // Place seats clockwise starting from the bottom (where the
                // hero usually sits in poker apps).
                left: cx + orbitRx * math.sin(_angle(i, positions.length)) -
                    seatSize / 2,
                top: cy - orbitRy * math.cos(_angle(i, positions.length)) -
                    seatSize / 2,
                width: seatSize,
                height: seatSize,
                child: _SeatBubble(
                  position: positions[i],
                  selected: i == selectedIndex,
                  onTap: () => onSelect(i),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Angle for seat [i] of [n] measured clockwise from the bottom.
  double _angle(int i, int n) {
    // Hero (typically BTN-ish for a chart) at the bottom = angle 0.
    return (2 * math.pi * i) / n;
  }
}

class _SeatBubble extends StatelessWidget {
  final PokerPosition position;
  final bool selected;
  final VoidCallback onTap;

  const _SeatBubble({
    required this.position,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final color = _tierColor(pt, position.tier);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: selected ? 0.55 : 0.25),
                color.withValues(alpha: 0.06),
              ],
            ),
            border: Border.all(
              color: selected
                  ? color
                  : color.withValues(alpha: 0.5),
              width: selected ? 2.5 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.55),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            position.abbreviation,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: position.abbreviation.length > 4 ? 10 : 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _PositionDetailCard extends StatelessWidget {
  final PokerPosition position;

  const _PositionDetailCard({required this.position});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    final color = _tierColor(pt, position.tier);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .animate(anim),
          child: child,
        ),
      ),
      child: Card(
        key: ValueKey(position.abbreviation),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: color.withValues(alpha: 0.4), width: 1),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.10),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      position.abbreviation,
                      style: textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      position.name,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    position.tier.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: pt.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                position.role,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.86),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded,
                      size: 14, color: pt.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      position.openingNote,
                      style: textTheme.bodySmall?.copyWith(
                        color: pt.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TierLegend extends StatelessWidget {
  const _TierLegend();

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final tier in PositionTier.values)
          _LegendDot(
            color: _tierColor(pt, tier),
            label: tier.label,
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: pt.surfaceDim,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

Color _tierColor(PokerTheme pt, PositionTier tier) {
  return switch (tier) {
    PositionTier.early => pt.positionEarly,
    PositionTier.middle => pt.positionMiddle,
    PositionTier.late => pt.positionLate,
    PositionTier.blinds => pt.positionBlinds,
  };
}
