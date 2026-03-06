import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';

final sessionsStreamProvider = StreamProvider.autoDispose<List<Session>>((ref) {
  return ref.watch(sessionsDaoProvider).watchAllSessions();
});

final addSessionProvider = Provider((ref) {
  return (SessionsCompanion entry) async {
    try {
      await ref.read(sessionsDaoProvider).insertSession(entry);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to add session: $e'), st);
    }
  };
});

final updateSessionProvider = Provider((ref) {
  return (SessionsCompanion entry) async {
    try {
      await ref.read(sessionsDaoProvider).updateSession(entry);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to update session: $e'), st);
    }
  };
});

final deleteSessionProvider = Provider((ref) {
  return (int id) async {
    try {
      await ref.read(sessionsDaoProvider).deleteSessionById(id);
    } catch (e, st) {
      Error.throwWithStackTrace(
          Exception('Failed to delete session: $e'), st);
    }
  };
});
