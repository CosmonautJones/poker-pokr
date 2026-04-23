import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'achievements.dart';
import 'progression_provider.dart';
import 'user_stats.dart';

final achievementsProvider =
    NotifierProvider<AchievementsNotifier, AchievementProgress>(
  AchievementsNotifier.new,
);

final recentlyUnlockedAchievementsProvider =
    NotifierProvider<RecentlyUnlockedNotifier, List<Achievement>>(
  RecentlyUnlockedNotifier.new,
);

class AchievementsNotifier extends Notifier<AchievementProgress> {
  @override
  AchievementProgress build() {
    return ref.read(userStatsServiceProvider).loadAchievements();
  }

  Future<void> evaluate({
    required UserStats stats,
    int? sessionProfitCents,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final newly = AchievementsCatalog.evaluate(
      stats: stats,
      current: state,
      now: ts,
      latestSessionProfitCents: sessionProfitCents,
    );
    if (newly.isEmpty) return;
    final updated = Map<String, DateTime>.from(state.unlockedAt);
    for (final a in newly) {
      updated[a.id] = ts;
    }
    final next = state.copyWith(unlockedAt: updated);
    state = next;
    await ref.read(userStatsServiceProvider).saveAchievements(next);
    ref
        .read(recentlyUnlockedAchievementsProvider.notifier)
        .enqueueAll(newly);
  }

  Future<void> reset() async {
    state = const AchievementProgress.empty();
    await ref.read(userStatsServiceProvider).saveAchievements(state);
  }
}

class RecentlyUnlockedNotifier extends Notifier<List<Achievement>> {
  @override
  List<Achievement> build() => const [];

  void enqueueAll(List<Achievement> items) {
    if (items.isEmpty) return;
    state = [...state, ...items];
  }

  Achievement? consumeFirst() {
    if (state.isEmpty) return null;
    final head = state.first;
    state = state.sublist(1);
    return head;
  }
}
