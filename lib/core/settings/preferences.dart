import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable snapshot of user preferences.
@immutable
class AppPreferences {
  /// Whether haptic feedback fires on taps, confirmations, and wins.
  final bool hapticsEnabled;

  const AppPreferences({
    this.hapticsEnabled = true,
  });

  AppPreferences copyWith({bool? hapticsEnabled}) {
    return AppPreferences(
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
    );
  }

  static const defaults = AppPreferences();
}

/// Keys for persisted preferences. Prefixed to avoid collisions with
/// other SharedPreferences entries outside this app's scope.
class _PrefKeys {
  static const haptics = 'pref.haptics_enabled';
}

/// Riverpod notifier that loads [AppPreferences] from [SharedPreferences]
/// and writes changes back. If the backing store has not initialized yet,
/// the provider yields [AppPreferences.defaults] so the UI never blocks.
class PreferencesNotifier extends AsyncNotifier<AppPreferences> {
  SharedPreferences? _prefs;

  @override
  Future<AppPreferences> build() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      return AppPreferences(
        hapticsEnabled:
            _prefs!.getBool(_PrefKeys.haptics) ?? AppPreferences.defaults.hapticsEnabled,
      );
    } catch (_) {
      // SharedPreferences can fail in headless test environments; degrade
      // gracefully rather than crashing the app.
      return AppPreferences.defaults;
    }
  }

  /// Toggle haptic feedback and persist.
  Future<void> setHapticsEnabled(bool value) async {
    final current = state.valueOrNull ?? AppPreferences.defaults;
    state = AsyncData(current.copyWith(hapticsEnabled: value));
    try {
      await _prefs?.setBool(_PrefKeys.haptics, value);
    } catch (_) {
      // Persistence failure is non-fatal — in-memory state is still updated.
    }
  }
}

/// Main preferences provider. Reads from [SharedPreferences] on first use.
final preferencesProvider =
    AsyncNotifierProvider<PreferencesNotifier, AppPreferences>(
  PreferencesNotifier.new,
);

/// Derived provider for the haptics-enabled flag. Overrideable in tests
/// via `ProviderScope(overrides: [hapticsEnabledProvider.overrideWithValue(false)])`.
final hapticsEnabledProvider = Provider<bool>((ref) {
  final prefs = ref.watch(preferencesProvider);
  return prefs.valueOrNull?.hapticsEnabled ??
      AppPreferences.defaults.hapticsEnabled;
});
