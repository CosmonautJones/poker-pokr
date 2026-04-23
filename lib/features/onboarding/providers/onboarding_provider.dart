import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/core/progression/progression_provider.dart';

final onboardingSeenProvider =
    NotifierProvider<OnboardingSeenNotifier, bool>(OnboardingSeenNotifier.new);

class OnboardingSeenNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(userStatsServiceProvider).loadOnboardingSeen();

  Future<void> setSeen(bool seen) async {
    state = seen;
    await ref.read(userStatsServiceProvider).saveOnboardingSeen(seen);
  }
}
