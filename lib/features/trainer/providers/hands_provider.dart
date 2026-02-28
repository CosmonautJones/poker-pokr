import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';

final handsStreamProvider = StreamProvider.autoDispose<List<Hand>>((ref) {
  return ref.watch(handsDaoProvider).watchAllHands();
});

/// Watches setup-only hands (saved for practice).
final savedSetupsStreamProvider = StreamProvider.autoDispose<List<Hand>>((ref) {
  return ref.watch(handsDaoProvider).watchSavedSetups();
});

/// Watches played (non-setup-only) hands.
final playedHandsStreamProvider =
    StreamProvider.autoDispose<List<Hand>>((ref) {
  return ref.watch(handsDaoProvider).watchPlayedHands();
});
