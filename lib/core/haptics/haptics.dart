import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/settings/preferences.dart';

/// Thin wrapper over [HapticFeedback] that respects a user-controlled
/// enable flag and skips silently on platforms without reliable haptic
/// support (web, desktop).
///
/// All methods are fire-and-forget (return `void`). Callers never need to
/// `await` or wrap in `unawaited` — failures on the platform channel are
/// swallowed rather than surfaced to the UI.
class Haptics {
  final bool _enabled;

  const Haptics({required bool enabled}) : _enabled = enabled;

  bool get _canFire {
    if (!_enabled) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// Subtle selection tick — use for toggles, slider steps, preset taps.
  void tap() {
    if (!_canFire) return;
    unawaited(HapticFeedback.selectionClick());
  }

  /// Light impact — use for low-consequence actions (e.g. fold).
  void light() {
    if (!_canFire) return;
    unawaited(HapticFeedback.lightImpact());
  }

  /// Medium impact — use for confirms (bet/raise, submit).
  void medium() {
    if (!_canFire) return;
    unawaited(HapticFeedback.mediumImpact());
  }

  /// Heavy impact — use for all-in, big commits.
  void heavy() {
    if (!_canFire) return;
    unawaited(HapticFeedback.heavyImpact());
  }

  /// Success pattern — heavy then light, 80ms apart.
  /// Use for hand-complete / winning moments.
  void success() {
    if (!_canFire) return;
    unawaited(_successPattern());
  }

  static Future<void> _successPattern() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }
}

/// Riverpod provider exposing a [Haptics] instance whose enable flag
/// reflects the current user preference.
final hapticsProvider = Provider<Haptics>((ref) {
  final enabled = ref.watch(hapticsEnabledProvider);
  return Haptics(enabled: enabled);
});
