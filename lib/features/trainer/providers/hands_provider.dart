import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/database/app_database.dart';
import 'package:poker_trainer/core/providers/database_provider.dart';

final handsStreamProvider = StreamProvider.autoDispose<List<Hand>>((ref) {
  return ref.watch(handsDaoProvider).watchAllHands();
});
