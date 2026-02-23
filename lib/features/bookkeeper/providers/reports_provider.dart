import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/bookkeeper/domain/report_generator.dart';
import 'package:poker_trainer/features/bookkeeper/domain/session_stats.dart';
import 'package:poker_trainer/features/bookkeeper/providers/sessions_provider.dart';

final reportsProvider = Provider<AsyncValue<SessionStats>>((ref) {
  final sessionsAsync = ref.watch(sessionsStreamProvider);
  return sessionsAsync.whenData(
    (sessions) => ReportGenerator.generate(sessions),
  );
});
