import 'package:flutter/material.dart';

/// Semantic color tokens for the poker app.
///
/// Access via `PokerTheme.of(context)` or the extension `context.poker`.
/// All poker-specific colors live here so widgets don't hardcode values.
class PokerTheme extends ThemeExtension<PokerTheme> {
  // ── Table felt ──
  final Color feltCenter;
  final Color feltEdge;
  final Color tableBorder;

  // ── Cards ──
  final Color cardFace;
  final Color cardPlaceholder;
  final Color cardBorder;
  final Color suitRed;
  final Color suitBlack;

  // ── Player seats ──
  final Color seatBackground;
  final Color seatActive;
  final Color seatActiveBorder;
  final Color seatActiveGlow;
  final Color seatBorderDefault;
  final Color seatBorderAllIn;

  // ── Action colors (buttons + history) ──
  final Color actionFold;
  final Color actionCheck;
  final Color actionCall;
  final Color actionBet;
  final Color actionAllIn;

  // ── Pot & chips ──
  final Color potText;
  final Color potBorder;
  final Color chipBet;
  final Color dealerChip;

  // ── Status badges ──
  final Color badgeAllIn;
  final Color badgeFold;

  // ── Educational / accent ──
  final Color accent;
  final Color accentMuted;
  final Color tooltipBackground;
  final Color tooltipBorder;

  // ── Position colors ──
  final Color positionEarly;
  final Color positionMiddle;
  final Color positionLate;
  final Color positionBlinds;

  // ── Profit / loss ──
  final Color profit;
  final Color loss;

  // ── Surface overlays ──
  final Color surfaceOverlay;
  final Color surfaceDim;
  final Color borderSubtle;
  final Color textMuted;

  const PokerTheme({
    required this.feltCenter,
    required this.feltEdge,
    required this.tableBorder,
    required this.cardFace,
    required this.cardPlaceholder,
    required this.cardBorder,
    required this.suitRed,
    required this.suitBlack,
    required this.seatBackground,
    required this.seatActive,
    required this.seatActiveBorder,
    required this.seatActiveGlow,
    required this.seatBorderDefault,
    required this.seatBorderAllIn,
    required this.actionFold,
    required this.actionCheck,
    required this.actionCall,
    required this.actionBet,
    required this.actionAllIn,
    required this.potText,
    required this.potBorder,
    required this.chipBet,
    required this.dealerChip,
    required this.badgeAllIn,
    required this.badgeFold,
    required this.accent,
    required this.accentMuted,
    required this.tooltipBackground,
    required this.tooltipBorder,
    required this.positionEarly,
    required this.positionMiddle,
    required this.positionLate,
    required this.positionBlinds,
    required this.profit,
    required this.loss,
    required this.surfaceOverlay,
    required this.surfaceDim,
    required this.borderSubtle,
    required this.textMuted,
  });

  /// Default dark theme values — matches the existing hardcoded palette.
  static const dark = PokerTheme(
    // Table
    feltCenter: Color(0xFF1B5E20),
    feltEdge: Color(0xFF0D3B12),
    tableBorder: Color(0xFF5D4037),
    // Cards
    cardFace: Color(0xFF1A1A2E),
    cardPlaceholder: Color(0xFF0D0D1A),
    cardBorder: Color(0xFF757575), // grey.shade600
    suitRed: Color(0xFFEF5350),     // red.shade400
    suitBlack: Colors.white,
    // Player seats
    seatBackground: Color(0xFF212121),
    seatActive: Color(0xFF1B5E20),
    seatActiveBorder: Color(0xFF69F0AE), // greenAccent
    seatActiveGlow: Color(0x4D69F0AE),  // greenAccent @ 0.3
    seatBorderDefault: Color(0xFF616161), // grey.shade700
    seatBorderAllIn: Color(0xFFFF9800),   // orange
    // Actions
    actionFold: Color(0xFFC62828),    // red.shade800
    actionCheck: Color(0xFF455A64),   // blueGrey.shade700
    actionCall: Color(0xFF2E7D32),    // green.shade800
    actionBet: Color(0xFFF57F17),     // amber.shade800
    actionAllIn: Color(0xFFBF360C),   // deepOrange.shade800
    // Pot & chips
    potText: Color(0xFFFFCA28),       // amber
    potBorder: Color(0x66FFCA28),     // amber @ 0.4
    chipBet: Color(0xFFEEFF41),       // yellowAccent
    dealerChip: Color(0xFFFFC107),    // amber
    // Status badges
    badgeAllIn: Color(0xFFEF6C00),    // orange.shade800
    badgeFold: Color(0xFF424242),     // grey.shade800
    // Educational / accent
    accent: Color(0xFFFFCA28),        // amber
    accentMuted: Color(0xFFFFE082),   // amber.shade200
    tooltipBackground: Color(0xFF2A2A2A),
    tooltipBorder: Color(0x66F57F17), // amber.shade700 @ 0.4
    // Position colors
    positionEarly: Color(0xFFEF9A9A),  // red.shade300 (careful)
    positionMiddle: Color(0xFFFFCC80), // orange.shade300
    positionLate: Color(0xFFA5D6A7),  // green.shade300 (opportunity)
    positionBlinds: Color(0xFF90CAF9), // blue.shade300
    // Profit / loss
    profit: Color(0xFF66BB6A),        // green.shade400
    loss: Color(0xFFEF5350),          // red.shade400
    // Surface overlays
    surfaceOverlay: Color(0x66000000),  // black38-ish
    surfaceDim: Color(0xFF121212),
    borderSubtle: Color(0xFF424242),    // grey.shade800
    textMuted: Color(0xB3FFFFFF),       // white70
  );

  /// Convenience accessor.
  static PokerTheme of(BuildContext context) {
    return Theme.of(context).extension<PokerTheme>() ?? PokerTheme.dark;
  }

  @override
  PokerTheme copyWith({
    Color? feltCenter,
    Color? feltEdge,
    Color? tableBorder,
    Color? cardFace,
    Color? cardPlaceholder,
    Color? cardBorder,
    Color? suitRed,
    Color? suitBlack,
    Color? seatBackground,
    Color? seatActive,
    Color? seatActiveBorder,
    Color? seatActiveGlow,
    Color? seatBorderDefault,
    Color? seatBorderAllIn,
    Color? actionFold,
    Color? actionCheck,
    Color? actionCall,
    Color? actionBet,
    Color? actionAllIn,
    Color? potText,
    Color? potBorder,
    Color? chipBet,
    Color? dealerChip,
    Color? badgeAllIn,
    Color? badgeFold,
    Color? accent,
    Color? accentMuted,
    Color? tooltipBackground,
    Color? tooltipBorder,
    Color? positionEarly,
    Color? positionMiddle,
    Color? positionLate,
    Color? positionBlinds,
    Color? profit,
    Color? loss,
    Color? surfaceOverlay,
    Color? surfaceDim,
    Color? borderSubtle,
    Color? textMuted,
  }) {
    return PokerTheme(
      feltCenter: feltCenter ?? this.feltCenter,
      feltEdge: feltEdge ?? this.feltEdge,
      tableBorder: tableBorder ?? this.tableBorder,
      cardFace: cardFace ?? this.cardFace,
      cardPlaceholder: cardPlaceholder ?? this.cardPlaceholder,
      cardBorder: cardBorder ?? this.cardBorder,
      suitRed: suitRed ?? this.suitRed,
      suitBlack: suitBlack ?? this.suitBlack,
      seatBackground: seatBackground ?? this.seatBackground,
      seatActive: seatActive ?? this.seatActive,
      seatActiveBorder: seatActiveBorder ?? this.seatActiveBorder,
      seatActiveGlow: seatActiveGlow ?? this.seatActiveGlow,
      seatBorderDefault: seatBorderDefault ?? this.seatBorderDefault,
      seatBorderAllIn: seatBorderAllIn ?? this.seatBorderAllIn,
      actionFold: actionFold ?? this.actionFold,
      actionCheck: actionCheck ?? this.actionCheck,
      actionCall: actionCall ?? this.actionCall,
      actionBet: actionBet ?? this.actionBet,
      actionAllIn: actionAllIn ?? this.actionAllIn,
      potText: potText ?? this.potText,
      potBorder: potBorder ?? this.potBorder,
      chipBet: chipBet ?? this.chipBet,
      dealerChip: dealerChip ?? this.dealerChip,
      badgeAllIn: badgeAllIn ?? this.badgeAllIn,
      badgeFold: badgeFold ?? this.badgeFold,
      accent: accent ?? this.accent,
      accentMuted: accentMuted ?? this.accentMuted,
      tooltipBackground: tooltipBackground ?? this.tooltipBackground,
      tooltipBorder: tooltipBorder ?? this.tooltipBorder,
      positionEarly: positionEarly ?? this.positionEarly,
      positionMiddle: positionMiddle ?? this.positionMiddle,
      positionLate: positionLate ?? this.positionLate,
      positionBlinds: positionBlinds ?? this.positionBlinds,
      profit: profit ?? this.profit,
      loss: loss ?? this.loss,
      surfaceOverlay: surfaceOverlay ?? this.surfaceOverlay,
      surfaceDim: surfaceDim ?? this.surfaceDim,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textMuted: textMuted ?? this.textMuted,
    );
  }

  @override
  PokerTheme lerp(ThemeExtension<PokerTheme>? other, double t) {
    if (other is! PokerTheme) return this;
    return PokerTheme(
      feltCenter: Color.lerp(feltCenter, other.feltCenter, t)!,
      feltEdge: Color.lerp(feltEdge, other.feltEdge, t)!,
      tableBorder: Color.lerp(tableBorder, other.tableBorder, t)!,
      cardFace: Color.lerp(cardFace, other.cardFace, t)!,
      cardPlaceholder: Color.lerp(cardPlaceholder, other.cardPlaceholder, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      suitRed: Color.lerp(suitRed, other.suitRed, t)!,
      suitBlack: Color.lerp(suitBlack, other.suitBlack, t)!,
      seatBackground: Color.lerp(seatBackground, other.seatBackground, t)!,
      seatActive: Color.lerp(seatActive, other.seatActive, t)!,
      seatActiveBorder: Color.lerp(seatActiveBorder, other.seatActiveBorder, t)!,
      seatActiveGlow: Color.lerp(seatActiveGlow, other.seatActiveGlow, t)!,
      seatBorderDefault: Color.lerp(seatBorderDefault, other.seatBorderDefault, t)!,
      seatBorderAllIn: Color.lerp(seatBorderAllIn, other.seatBorderAllIn, t)!,
      actionFold: Color.lerp(actionFold, other.actionFold, t)!,
      actionCheck: Color.lerp(actionCheck, other.actionCheck, t)!,
      actionCall: Color.lerp(actionCall, other.actionCall, t)!,
      actionBet: Color.lerp(actionBet, other.actionBet, t)!,
      actionAllIn: Color.lerp(actionAllIn, other.actionAllIn, t)!,
      potText: Color.lerp(potText, other.potText, t)!,
      potBorder: Color.lerp(potBorder, other.potBorder, t)!,
      chipBet: Color.lerp(chipBet, other.chipBet, t)!,
      dealerChip: Color.lerp(dealerChip, other.dealerChip, t)!,
      badgeAllIn: Color.lerp(badgeAllIn, other.badgeAllIn, t)!,
      badgeFold: Color.lerp(badgeFold, other.badgeFold, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentMuted: Color.lerp(accentMuted, other.accentMuted, t)!,
      tooltipBackground: Color.lerp(tooltipBackground, other.tooltipBackground, t)!,
      tooltipBorder: Color.lerp(tooltipBorder, other.tooltipBorder, t)!,
      positionEarly: Color.lerp(positionEarly, other.positionEarly, t)!,
      positionMiddle: Color.lerp(positionMiddle, other.positionMiddle, t)!,
      positionLate: Color.lerp(positionLate, other.positionLate, t)!,
      positionBlinds: Color.lerp(positionBlinds, other.positionBlinds, t)!,
      profit: Color.lerp(profit, other.profit, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      surfaceOverlay: Color.lerp(surfaceOverlay, other.surfaceOverlay, t)!,
      surfaceDim: Color.lerp(surfaceDim, other.surfaceDim, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

/// Shorthand so widgets can write `context.poker.accent`.
extension PokerThemeContext on BuildContext {
  PokerTheme get poker => PokerTheme.of(this);
}
