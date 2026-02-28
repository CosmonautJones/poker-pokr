import 'package:flutter/animation.dart';

/// Shared animation constants for the premium poker UI.
abstract final class PokerAnimations {
  // ── Durations ──
  static const kCardFlip = Duration(milliseconds: 600);
  static const kCardShimmer = Duration(milliseconds: 800);
  static const kButtonPress = Duration(milliseconds: 80);
  static const kButtonRelease = Duration(milliseconds: 200);
  static const kGlowPulse = Duration(milliseconds: 2000);
  static const kTurnSweep = Duration(milliseconds: 2000);
  static const kWinnerRing = Duration(milliseconds: 800);
  static const kWinnerSparkle = Duration(milliseconds: 1500);
  static const kPotFlash = Duration(milliseconds: 300);
  static const kFold = Duration(milliseconds: 400);
  static const kShimmer = Duration(milliseconds: 3000);
  static const kBetSlideIn = Duration(milliseconds: 350);
  static const kDealerEntrance = Duration(milliseconds: 450);
  static const kChipWobble = Duration(milliseconds: 500);
  static const kSliderReveal = Duration(milliseconds: 300);
  static const kContextChipEntrance = Duration(milliseconds: 300);
  static const kTipEntrance = Duration(milliseconds: 400);
  static const kCoachingEntrance = Duration(milliseconds: 500);

  // ── Curves ──
  static const buttonPressCurve = Curves.easeInCubic;
  static const buttonReleaseCurve = Curves.elasticOut;
  static const badgeEntranceCurve = Curves.easeOutBack;
  static const betSlideCurve = Curves.easeOutBack;
  static const dealerEntranceCurve = Curves.elasticOut;
  static const tipEntranceCurve = Curves.easeOutCubic;

  /// Stagger delay for sequential card deals (e.g. flop).
  static Duration cardStaggerDelay(int index) =>
      Duration(milliseconds: 80 * index);
}
