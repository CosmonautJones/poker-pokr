import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';

/// Notifier that manages the create-hand form state.
class HandSetupNotifier extends Notifier<HandSetup> {
  @override
  HandSetup build() => HandSetup.defaults(playerCount: 6);

  void setPlayerCount(int count) {
    final current = state;
    // Adjust names and stacks lists to match new count.
    final names = List.generate(count, (i) {
      if (i < current.playerNames.length) return current.playerNames[i];
      return 'Player ${i + 1}';
    });
    final stacks = List.generate(count, (i) {
      if (i < current.stacks.length) return current.stacks[i];
      return current.bigBlind * 100;
    });
    // Clamp dealer index if needed.
    final dealer =
        current.dealerIndex >= count ? 0 : current.dealerIndex;
    state = current.copyWith(
      playerCount: count,
      playerNames: names,
      stacks: stacks,
      dealerIndex: dealer,
    );
  }

  void setSmallBlind(double sb) {
    state = state.copyWith(smallBlind: sb);
  }

  void setBigBlind(double bb) {
    state = state.copyWith(bigBlind: bb);
  }

  void setAnte(double ante) {
    state = state.copyWith(ante: ante);
  }

  void setDealerIndex(int index) {
    state = state.copyWith(dealerIndex: index);
  }

  void setPlayerName(int index, String name) {
    final names = List<String>.of(state.playerNames);
    names[index] = name;
    state = state.copyWith(playerNames: names);
  }

  void setPlayerStack(int index, double stack) {
    final stacks = List<double>.of(state.stacks);
    stacks[index] = stack;
    state = state.copyWith(stacks: stacks);
  }
}

final handSetupProvider =
    NotifierProvider<HandSetupNotifier, HandSetup>(HandSetupNotifier.new);

/// Holds the active HandSetup for a new hand being played.
/// null means no active new hand (i.e. loading a saved hand instead).
final activeHandSetupProvider = StateProvider<HandSetup?>((ref) => null);
