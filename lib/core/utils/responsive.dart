import 'package:flutter/widgets.dart';

/// Lightweight responsive utilities for phone-sized screens (320–430pt).
///
/// Normalizes on a 375pt baseline (iPhone SE/8 standard).
class Responsive {
  Responsive._();

  /// Scale factor relative to 375pt baseline, clamped for safety.
  static double scale(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return (width / 375).clamp(0.85, 1.15);
  }

  /// Horizontal padding that adapts to screen width.
  static EdgeInsets hPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final h = width < 360 ? 12.0 : 16.0;
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Returns [small] when screen width < 360, [standard] otherwise.
  static T value<T>(BuildContext context, {required T small, required T standard}) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 360 ? small : standard;
  }

  /// Whether this is a compact screen (< 360pt).
  static bool isCompact(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 360;
  }
}
