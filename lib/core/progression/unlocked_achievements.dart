import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Immutable mapping of achievement id → unlock timestamp.
@immutable
class UnlockedAchievements {
  /// SharedPreferences key.
  static const storageKey = 'unlocked_achievements_v1';

  final Map<String, DateTime> unlockedAt;

  const UnlockedAchievements._(this.unlockedAt);

  /// No achievements unlocked yet.
  const UnlockedAchievements.empty() : unlockedAt = const {};

  bool contains(String id) => unlockedAt.containsKey(id);
  int get count => unlockedAt.length;

  /// Returns a new instance with [id] marked unlocked at [at].
  /// If [id] is already unlocked, the existing timestamp is preserved.
  UnlockedAchievements copyWithUnlock(String id, DateTime at) {
    if (unlockedAt.containsKey(id)) return this;
    final next = Map<String, DateTime>.from(unlockedAt);
    next[id] = at;
    return UnlockedAchievements._(next);
  }

  Map<String, dynamic> toJson() => {
        for (final e in unlockedAt.entries) e.key: e.value.toIso8601String(),
      };

  String encode() => jsonEncode(toJson());

  /// Tolerant decoder: returns [empty] for null/empty/malformed input.
  static UnlockedAchievements tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return const UnlockedAchievements.empty();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final result = <String, DateTime>{};
      for (final entry in map.entries) {
        final v = entry.value;
        if (v is String) {
          final ts = DateTime.tryParse(v);
          if (ts != null) result[entry.key] = ts;
        }
      }
      return UnlockedAchievements._(result);
    } catch (_) {
      return const UnlockedAchievements.empty();
    }
  }
}
