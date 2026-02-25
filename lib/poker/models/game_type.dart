/// Supported poker game variants.
///
/// Pure Dart - no Flutter imports.
library;

enum GameType {
  texasHoldem,
  omaha;

  /// Number of hole cards dealt to each player.
  int get holeCardCount => switch (this) {
        GameType.texasHoldem => 2,
        GameType.omaha => 4,
      };

  /// Human-readable name for display.
  String get displayName => switch (this) {
        GameType.texasHoldem => "Texas Hold'em",
        GameType.omaha => 'Omaha',
      };
}
