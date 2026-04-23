import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';
import 'package:poker_trainer/features/settings/domain/personalization.dart';

final personalizationProvider =
    NotifierProvider<PersonalizationNotifier, PersonalizationSettings>(
  PersonalizationNotifier.new,
);

class PersonalizationNotifier extends Notifier<PersonalizationSettings> {
  @override
  PersonalizationSettings build() =>
      ref.read(userStatsServiceProvider).loadPersonalization();

  Future<void> setCardBack(CardBackStyle style) async {
    if (state.cardBack == style) return;
    state = state.copyWith(cardBack: style);
    await ref.read(userStatsServiceProvider).savePersonalization(state);
  }

  Future<void> setFelt(TableFeltColor felt) async {
    if (state.felt == felt) return;
    state = state.copyWith(felt: felt);
    await ref.read(userStatsServiceProvider).savePersonalization(state);
  }

  Future<void> setSound(SoundProfile sound) async {
    if (state.sound == sound) return;
    state = state.copyWith(sound: sound);
    await ref.read(userStatsServiceProvider).savePersonalization(state);
  }
}
