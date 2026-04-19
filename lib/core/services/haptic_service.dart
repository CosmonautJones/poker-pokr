import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../progression/progression_provider.dart';

/// Thin wrapper over [HapticFeedback] that honors the user's preference and
/// keeps call sites clean. Read via [WidgetRef.read] so calls don't trigger
/// rebuilds.
class HapticService {
  final bool _enabled;

  const HapticService({required bool enabled}) : _enabled = enabled;

  /// Light tap for neutral selections (pill toggles, fold).
  void selection() {
    if (!_enabled) return;
    HapticFeedback.selectionClick();
  }

  /// Soft confirmation (check, call).
  void light() {
    if (!_enabled) return;
    HapticFeedback.lightImpact();
  }

  /// Positive / assertive action (bet, raise, lesson progress).
  void medium() {
    if (!_enabled) return;
    HapticFeedback.mediumImpact();
  }

  /// Big moment (all-in, winner reveal, level-up).
  void heavy() {
    if (!_enabled) return;
    HapticFeedback.heavyImpact();
  }

  /// Celebration double-tap used for wins / achievements.
  Future<void> success() async {
    if (!_enabled) return;
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    await HapticFeedback.heavyImpact();
  }
}

final hapticServiceProvider = Provider<HapticService>((ref) {
  final enabled = ref.watch(hapticsEnabledProvider);
  return HapticService(enabled: enabled);
});
