import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:poker_trainer/core/animations/poker_animations.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';
import 'package:poker_trainer/poker/models/card.dart';

/// Displays the community cards (0-5) in a horizontal row with
/// cinematic 3D-flip deal animations and staggered timing.
class CommunityCardsWidget extends StatelessWidget {
  final List<PokerCard> cards;
  final double scale;

  const CommunityCardsWidget({
    super.key,
    required this.cards,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < cards.length) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2 * scale),
            child: _CardFlipDeal(
              key: ValueKey('community_${cards[i].rank}_${cards[i].suit}'),
              dealIndex: i,
              child: _CardFace(card: cards[i], scale: scale),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 2 * scale),
          child: _CardPlaceholder(scale: scale),
        );
      }),
    );
  }
}

/// Cinematic 3D card deal: slide-in phase → Y-axis flip from back to face.
class _CardFlipDeal extends StatefulWidget {
  final Widget child;
  final int dealIndex;

  const _CardFlipDeal({
    super.key,
    required this.child,
    this.dealIndex = 0,
  });

  @override
  State<_CardFlipDeal> createState() => _CardFlipDealState();
}

class _CardFlipDealState extends State<_CardFlipDeal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Phase 1: slide-in + scale (0.0 → 0.5)
  late Animation<double> _slideProgress;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // Phase 2: flip (0.5 → 1.0)
  late Animation<double> _flipProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PokerAnimations.kCardFlip,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    _slideProgress = Tween<double>(begin: -0.3, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    _flipProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutCubic),
      ),
    );

    // Stagger based on deal index.
    Future.delayed(PokerAnimations.cardStaggerDelay(widget.dealIndex), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // Phase 1: slide + scale + fade
        final slide = _slideProgress.value;
        final scaleVal = _scaleAnimation.value;
        final opacity = _fadeAnimation.value;

        // Phase 2: Y-axis flip (0→0.5 = back rotating to 90°, 0.5→1 = face from -90° to 0°)
        final flip = _flipProgress.value;
        final showFace = flip >= 0.5;
        final flipAngle = showFace
            ? math.pi * (1.0 - flip) // -90° → 0°
            : math.pi * flip; // 0° → 90°

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, slide * 40),
            child: Transform.scale(
              scale: scaleVal,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(flipAngle),
                child: showFace
                    ? widget.child
                    : _CardBack(
                        width: null,
                        height: null,
                        scale: 1.0,
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Card back design — indigo gradient with decorative gold pattern.
class _CardBack extends StatelessWidget {
  final double? width;
  final double? height;
  final double scale;

  const _CardBack({this.width, this.height, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final w = width ?? (48 * scale).clamp(34.0, 52.0);
    final h = height ?? (68 * scale).clamp(48.0, 74.0);
    final r = (8 * scale).clamp(4.0, 10.0);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [pt.cardBackPrimary, pt.cardBackSecondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: pt.goldDark.withValues(alpha: 0.3),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(1.5, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            // Decorative nested rectangles
            Center(
              child: Container(
                width: w * 0.65,
                height: h * 0.7,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r * 0.6),
                  border: Border.all(
                    color: pt.goldDark.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: w * 0.45,
                    height: h * 0.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(r * 0.4),
                      border: Border.all(
                        color: pt.goldDark.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Subtle diagonal sheen
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(r),
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Premium white card face with realistic suit colors and glossy sheen.
class _CardFace extends StatelessWidget {
  final PokerCard card;
  final double scale;

  const _CardFace({required this.card, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final suitColor = isRed ? pt.suitRed : pt.suitBlack;

    final w = (48 * scale).clamp(34.0, 52.0);
    final h = (68 * scale).clamp(48.0, 74.0);
    final r = (8 * scale).clamp(4.0, 10.0);

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pt.cardFaceWhite,
            Color.lerp(pt.cardFaceWhite, Colors.grey.shade200, 0.3)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 6,
            offset: const Offset(1.5, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 2,
            offset: const Offset(0.5, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(r),
        child: Stack(
          children: [
            // Top-edge sheen — specular reflection
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: h * 0.3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      pt.cardSheen,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            // Card content — rank and suit
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      card.rank.symbol,
                      style: TextStyle(
                        color: suitColor,
                        fontSize: (20 * scale).clamp(14.0, 22.0),
                        fontWeight: FontWeight.w800,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: suitColor.withValues(alpha: 0.15),
                            blurRadius: 1,
                            offset: const Offset(0, 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    card.suit.symbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: (18 * scale).clamp(12.0, 20.0),
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom inner shadow — depth on the card face
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: h * 0.15,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A grayed-out placeholder for an undealt card slot.
class _CardPlaceholder extends StatelessWidget {
  final double scale;

  const _CardPlaceholder({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final w = (48 * scale).clamp(34.0, 52.0);
    final h = (68 * scale).clamp(48.0, 74.0);
    final r = (8 * scale).clamp(4.0, 10.0);
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: pt.cardPlaceholder,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: pt.borderSubtle.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
    );
  }
}

/// A small card widget for display in player seats (hole cards).
/// Premium white face treatment matching community cards.
class MiniCardWidget extends StatelessWidget {
  final PokerCard card;
  final bool faceDown;
  final double scale;

  const MiniCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final pt = context.poker;
    final isRed = card.suit == Suit.hearts || card.suit == Suit.diamonds;
    final suitColor = isRed ? pt.suitRed : pt.suitBlack;

    final w = (30 * scale).clamp(22.0, 34.0);
    final h = (42 * scale).clamp(30.0, 46.0);
    final r = (5 * scale).clamp(3.0, 6.0);

    if (faceDown) {
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [pt.cardBackPrimary, pt.cardBackSecondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(r),
          border: Border.all(
            color: pt.goldDark.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 2,
              offset: const Offset(0.5, 1),
            ),
          ],
        ),
      );
    }

    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            pt.cardFaceWhite,
            Color.lerp(pt.cardFaceWhite, Colors.grey.shade200, 0.2)!,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0.5, 1.5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Sheen
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: h * 0.3,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(r),
                ),
                gradient: LinearGradient(
                  colors: [
                    pt.cardSheen,
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    card.rank.symbol,
                    style: TextStyle(
                      color: suitColor,
                      fontSize: (13 * scale).clamp(9.0, 15.0),
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
                Text(
                  card.suit.symbol,
                  style: TextStyle(
                    color: suitColor,
                    fontSize: (11 * scale).clamp(8.0, 13.0),
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
