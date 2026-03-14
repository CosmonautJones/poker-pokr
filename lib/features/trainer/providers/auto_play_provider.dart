import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:poker_trainer/features/trainer/domain/hand_setup.dart';
import 'package:poker_trainer/features/trainer/providers/hand_replay_provider.dart';
import 'package:poker_trainer/poker/engine/random_action_selector.dart';

/// Speed presets for auto-play.
enum AutoPlaySpeed {
  fast(Duration(milliseconds: 300), 'Fast'),
  normal(Duration(milliseconds: 800), 'Normal'),
  slow(Duration(milliseconds: 1500), 'Slow');

  final Duration delay;
  final String label;
  const AutoPlaySpeed(this.delay, this.label);
}

class AutoPlayState {
  final bool isRunning;
  final bool isPaused;
  final AutoPlaySpeed speed;
  final int actionsPlayed;

  const AutoPlayState({
    this.isRunning = false,
    this.isPaused = false,
    this.speed = AutoPlaySpeed.normal,
    this.actionsPlayed = 0,
  });

  AutoPlayState copyWith({
    bool? isRunning,
    bool? isPaused,
    AutoPlaySpeed? speed,
    int? actionsPlayed,
  }) {
    return AutoPlayState(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      speed: speed ?? this.speed,
      actionsPlayed: actionsPlayed ?? this.actionsPlayed,
    );
  }
}

class AutoPlayNotifier extends AutoDisposeFamilyNotifier<AutoPlayState, HandSetup> {
  Timer? _timer;
  final Random _rng = Random();

  @override
  AutoPlayState build(HandSetup arg) {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return const AutoPlayState();
  }

  /// Start auto-play. Each tick applies a random legal action.
  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, isPaused: false, actionsPlayed: 0);
    _scheduleNext();
  }

  /// Pause auto-play (timer stops, state preserved).
  void pause() {
    if (!state.isRunning || state.isPaused) return;
    _timer?.cancel();
    state = state.copyWith(isPaused: true);
  }

  /// Resume from pause.
  void resume() {
    if (!state.isRunning || !state.isPaused) return;
    state = state.copyWith(isPaused: false);
    _scheduleNext();
  }

  /// Stop auto-play entirely.
  void stop() {
    _timer?.cancel();
    state = const AutoPlayState();
  }

  /// Change playback speed.
  void setSpeed(AutoPlaySpeed speed) {
    state = state.copyWith(speed: speed);
    // If running and not paused, restart the timer with new speed.
    if (state.isRunning && !state.isPaused) {
      _timer?.cancel();
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(state.speed.delay, _tick);
  }

  void _tick() {
    if (!state.isRunning || state.isPaused) return;

    final replayState = ref.read(handReplayProvider(arg));
    if (replayState.isComplete) {
      state = state.copyWith(isRunning: false, isPaused: false);
      return;
    }

    try {
      final action = RandomActionSelector.selectAction(
        replayState.gameState,
        random: _rng,
      );
      ref.read(handReplayProvider(arg).notifier).applyAction(action);
      state = state.copyWith(actionsPlayed: state.actionsPlayed + 1);
    } catch (_) {
      // If action selection fails, stop auto-play.
      stop();
      return;
    }

    // Check if hand completed after this action.
    final newReplayState = ref.read(handReplayProvider(arg));
    if (newReplayState.isComplete) {
      state = state.copyWith(isRunning: false, isPaused: false);
      return;
    }

    _scheduleNext();
  }
}

final autoPlayProvider = NotifierProvider.autoDispose
    .family<AutoPlayNotifier, AutoPlayState, HandSetup>(
  AutoPlayNotifier.new,
);
