/// Betting streets in a Texas Hold'em hand.
///
/// Pure Dart - no Flutter imports.
library;

enum Street {
  preflop,
  flop,
  turn,
  river,
  showdown;

  /// Returns the next street in the progression.
  ///
  /// [showdown] returns itself (terminal state).
  Street get next => switch (this) {
        Street.preflop => Street.flop,
        Street.flop => Street.turn,
        Street.turn => Street.river,
        Street.river => Street.showdown,
        Street.showdown => Street.showdown,
      };

  /// Whether this street is a terminal state (no further betting).
  bool get isTerminal => this == Street.showdown;
}
