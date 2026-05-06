import 'dart:convert';

/// Per-achievement progress + unlock timestamp. Persisted as JSON.
class AchievementProgress {
  final int value;
  final DateTime? unlockedAt;

  const AchievementProgress({required this.value, this.unlockedAt});

  bool get isUnlocked => unlockedAt != null;

  AchievementProgress copyWith({int? value, DateTime? unlockedAt}) =>
      AchievementProgress(
        value: value ?? this.value,
        unlockedAt: unlockedAt ?? this.unlockedAt,
      );

  Map<String, dynamic> toJson() => {
        'v': value,
        if (unlockedAt != null) 'u': unlockedAt!.toIso8601String(),
      };

  static AchievementProgress fromJson(Map<String, dynamic> map) {
    return AchievementProgress(
      value: (map['v'] as num?)?.toInt() ?? 0,
      unlockedAt: map['u'] is String
          ? DateTime.tryParse(map['u'] as String)
          : null,
    );
  }
}

/// Wire-format wrapper over the per-id progress map. Persisted as a single
/// JSON string under [storageKey] so the schema can evolve without migrations.
class AchievementsState {
  static const storageKey = 'achievements_v1';

  final Map<String, AchievementProgress> byId;

  const AchievementsState({required this.byId});

  const AchievementsState.empty() : byId = const {};

  AchievementProgress progressFor(String id) =>
      byId[id] ?? const AchievementProgress(value: 0);

  AchievementsState withProgress(String id, AchievementProgress p) {
    final next = Map<String, AchievementProgress>.from(byId);
    next[id] = p;
    return AchievementsState(byId: next);
  }

  /// Total number of unlocked achievements.
  int get unlockedCount =>
      byId.values.where((p) => p.isUnlocked).length;

  String encode() {
    final out = <String, dynamic>{};
    byId.forEach((k, v) => out[k] = v.toJson());
    return jsonEncode(out);
  }

  static AchievementsState? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final byId = <String, AchievementProgress>{};
      map.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          byId[k] = AchievementProgress.fromJson(v);
        }
      });
      return AchievementsState(byId: byId);
    } catch (_) {
      return null;
    }
  }
}
