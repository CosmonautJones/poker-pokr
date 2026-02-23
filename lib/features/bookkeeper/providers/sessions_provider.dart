import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';

final sessionsStreamProvider = StreamProvider<List<Session>>((ref) {
  return ref.watch(sessionsDaoProvider).watchAllSessions();
});

final addSessionProvider = Provider((ref) {
  return (SessionsCompanion entry) =>
      ref.read(sessionsDaoProvider).insertSession(entry);
});

final updateSessionProvider = Provider((ref) {
  return (SessionsCompanion entry) =>
      ref.read(sessionsDaoProvider).updateSession(entry);
});

final deleteSessionProvider = Provider((ref) {
  return (int id) => ref.read(sessionsDaoProvider).deleteSessionById(id);
});
