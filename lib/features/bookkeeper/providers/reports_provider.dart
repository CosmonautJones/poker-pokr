import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/bookkeeper/domain/report_generator.dart';
import 'package:poker_trainer/features/bookkeeper/domain/session_stats.dart';
import 'package:poker_trainer/features/bookkeeper/providers/sessions_provider.dart';

final reportsProvider = Provider<AsyncValue<SessionStats>>((ref) {
  final sessionsAsync = ref.watch(sessionsStreamProvider);
  return sessionsAsync.when(
    data: (sessions) {
      try {
        return AsyncValue.data(ReportGenerator.generate(sessions));
      } catch (e, st) {
        return AsyncValue.error(e, st);
      }
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
