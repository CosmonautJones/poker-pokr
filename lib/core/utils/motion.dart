import 'package:flutter/widgets.dart';

/// Reduced-motion utilities for accessibility.
///
/// Honors the platform's "Reduce Motion" setting so continuously-running
/// animations can be disabled for users who need it.
class Motion {
  Motion._();

  /// Whether animations should play. Returns false when the user has
  /// enabled "Reduce Motion" in system accessibility settings.
  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// Returns [normal] duration when animations are enabled,
  /// [Duration.zero] when reduced motion is on.
  static Duration scaled(BuildContext context, Duration normal) {
    return shouldAnimate(context) ? normal : Duration.zero;
  }
}
