import 'package:flutter/material.dart';

/// Semantic color tokens for the poker app.
///
/// Access via `PokerTheme.of(context)` or the extension `context.poker`.
/// All poker-specific colors live here so widgets don't hardcode values.
class PokerTheme extends ThemeExtension<PokerTheme> {
  // ── Table felt ──
  final Color feltCenter;
  final Color feltEdge;
  final Color feltHighlight;
  final Color tableBorder;

  // ── Gold / metallic system ──
  final Color goldPrimary;
  final Color goldLight;
  final Color goldDark;

  // ── Cards ──
  final Color cardFace;
  final Color cardFaceWhite;
  final Color cardPlaceholder;
  final Color cardBorder;
  final Color cardSheen;
  final Color cardBackPrimary;
  final Color cardBackSecondary;
  final Color suitRed;
  final Color suitBlack;

  // ── Player seats ──
  final Color seatBackground;
  final Color seatActive;
  final Color seatActiveBorder;
  final Color seatActiveGlow;
  final Color seatBorderDefault;
  final Color seatBorderAllIn;
  final Color turnIndicatorGlow;

  // ── Action colors (buttons + history) ──
  final Color actionFold;
  final Color actionCheck;
  final Color actionCall;
  final Color actionBet;
  final Color actionAllIn;
  final Color buttonSheen;

  // ── Pot & chips ──
  final Color potText;
  final Color potBorder;
  final Color chipBet;
  final Color dealerChip;
  final Color chipWhite;
  final Color chipRed;
  final Color chipBlue;
  final Color chipGreen;

  // ── Status badges ──
  final Color badgeAllIn;
  final Color badgeFold;

  // ── Glow / effects ──
  final Color winnerGlow;
  final Color allInGlow;

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
    required this.feltHighlight,
    required this.tableBorder,
    required this.goldPrimary,
    required this.goldLight,
    required this.goldDark,
    required this.cardFace,
    required this.cardFaceWhite,
    required this.cardPlaceholder,
    required this.cardBorder,
    required this.cardSheen,
    required this.cardBackPrimary,
    required this.cardBackSecondary,
    required this.suitRed,
    required this.suitBlack,
    required this.seatBackground,
    required this.seatActive,
    required this.seatActiveBorder,
    required this.seatActiveGlow,
    required this.seatBorderDefault,
    required this.seatBorderAllIn,
    required this.turnIndicatorGlow,
    required this.actionFold,
    required this.actionCheck,
    required this.actionCall,
    required this.actionBet,
    required this.actionAllIn,
    required this.buttonSheen,
    required this.potText,
    required this.potBorder,
    required this.chipBet,
    required this.dealerChip,
    required this.chipWhite,
    required this.chipRed,
    required this.chipBlue,
    required this.chipGreen,
    required this.badgeAllIn,
    required this.badgeFold,
    required this.winnerGlow,
    required this.allInGlow,
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

  /// Default dark theme values — premium EA-Sports-inspired palette.
  static const dark = PokerTheme(
    // Table
    feltCenter: Color(0xFF1B5E20),
    feltEdge: Color(0xFF0D3B12),
    feltHighlight: Color(0xFF267029),
    tableBorder: Color(0xFF5D4037),
    // Gold / metallic
    goldPrimary: Color(0xFFD4AF37),
    goldLight: Color(0xFFE8D48B),
    goldDark: Color(0xFF8B7D3C),
    // Cards
    cardFace: Color(0xFF1A1A2E),
    cardFaceWhite: Color(0xFFF5F5F0),
    cardPlaceholder: Color(0xFF0D0D1A),
    cardBorder: Color(0xFF757575),
    cardSheen: Color(0x14FFFFFF),
    cardBackPrimary: Color(0xFF1A237E),
    cardBackSecondary: Color(0xFF283593),
    suitRed: Color(0xFFD50000),
    suitBlack: Color(0xFF212121),
    // Player seats
    seatBackground: Color(0xFF212121),
    seatActive: Color(0xFF1B5E20),
    seatActiveBorder: Color(0xFF69F0AE),
    seatActiveGlow: Color(0x4D69F0AE),
    seatBorderDefault: Color(0xFF616161),
    seatBorderAllIn: Color(0xFFFF9800),
    turnIndicatorGlow: Color(0xFF00E5FF),
    // Actions
    actionFold: Color(0xFFC62828),
    actionCheck: Color(0xFF455A64),
    actionCall: Color(0xFF2E7D32),
    actionBet: Color(0xFFF57F17),
    actionAllIn: Color(0xFFBF360C),
    buttonSheen: Color(0x14FFFFFF),
    // Pot & chips
    potText: Color(0xFFFFCA28),
    potBorder: Color(0x66FFCA28),
    chipBet: Color(0xFFEEFF41),
    dealerChip: Color(0xFFFFC107),
    chipWhite: Color(0xFFF5F5F5),
    chipRed: Color(0xFFE53935),
    chipBlue: Color(0xFF1E88E5),
    chipGreen: Color(0xFF43A047),
    // Status badges
    badgeAllIn: Color(0xFFEF6C00),
    badgeFold: Color(0xFF424242),
    // Glow / effects
    winnerGlow: Color(0xFFD4AF37),
    allInGlow: Color(0xFFFF6D00),
    // Educational / accent
    accent: Color(0xFFFFCA28),
    accentMuted: Color(0xFFFFE082),
    tooltipBackground: Color(0xFF2A2A2A),
    tooltipBorder: Color(0x66F57F17),
    // Position colors
    positionEarly: Color(0xFFEF9A9A),
    positionMiddle: Color(0xFFFFCC80),
    positionLate: Color(0xFFA5D6A7),
    positionBlinds: Color(0xFF90CAF9),
    // Profit / loss
    profit: Color(0xFF66BB6A),
    loss: Color(0xFFEF5350),
    // Surface overlays
    surfaceOverlay: Color(0x66000000),
    surfaceDim: Color(0xFF121212),
    borderSubtle: Color(0xFF424242),
    textMuted: Color(0xB3FFFFFF),
  );

  /// Convenience accessor.
  static PokerTheme of(BuildContext context) {
    return Theme.of(context).extension<PokerTheme>() ?? PokerTheme.dark;
  }

  @override
  PokerTheme copyWith({
    Color? feltCenter,
    Color? feltEdge,
    Color? feltHighlight,
    Color? tableBorder,
    Color? goldPrimary,
    Color? goldLight,
    Color? goldDark,
    Color? cardFace,
    Color? cardFaceWhite,
    Color? cardPlaceholder,
    Color? cardBorder,
    Color? cardSheen,
    Color? cardBackPrimary,
    Color? cardBackSecondary,
    Color? suitRed,
    Color? suitBlack,
    Color? seatBackground,
    Color? seatActive,
    Color? seatActiveBorder,
    Color? seatActiveGlow,
    Color? seatBorderDefault,
    Color? seatBorderAllIn,
    Color? turnIndicatorGlow,
    Color? actionFold,
    Color? actionCheck,
    Color? actionCall,
    Color? actionBet,
    Color? actionAllIn,
    Color? buttonSheen,
    Color? potText,
    Color? potBorder,
    Color? chipBet,
    Color? dealerChip,
    Color? chipWhite,
    Color? chipRed,
    Color? chipBlue,
    Color? chipGreen,
    Color? badgeAllIn,
    Color? badgeFold,
    Color? winnerGlow,
    Color? allInGlow,
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
      feltHighlight: feltHighlight ?? this.feltHighlight,
      tableBorder: tableBorder ?? this.tableBorder,
      goldPrimary: goldPrimary ?? this.goldPrimary,
      goldLight: goldLight ?? this.goldLight,
      goldDark: goldDark ?? this.goldDark,
      cardFace: cardFace ?? this.cardFace,
      cardFaceWhite: cardFaceWhite ?? this.cardFaceWhite,
      cardPlaceholder: cardPlaceholder ?? this.cardPlaceholder,
      cardBorder: cardBorder ?? this.cardBorder,
      cardSheen: cardSheen ?? this.cardSheen,
      cardBackPrimary: cardBackPrimary ?? this.cardBackPrimary,
      cardBackSecondary: cardBackSecondary ?? this.cardBackSecondary,
      suitRed: suitRed ?? this.suitRed,
      suitBlack: suitBlack ?? this.suitBlack,
      seatBackground: seatBackground ?? this.seatBackground,
      seatActive: seatActive ?? this.seatActive,
      seatActiveBorder: seatActiveBorder ?? this.seatActiveBorder,
      seatActiveGlow: seatActiveGlow ?? this.seatActiveGlow,
      seatBorderDefault: seatBorderDefault ?? this.seatBorderDefault,
      seatBorderAllIn: seatBorderAllIn ?? this.seatBorderAllIn,
      turnIndicatorGlow: turnIndicatorGlow ?? this.turnIndicatorGlow,
      actionFold: actionFold ?? this.actionFold,
      actionCheck: actionCheck ?? this.actionCheck,
      actionCall: actionCall ?? this.actionCall,
      actionBet: actionBet ?? this.actionBet,
      actionAllIn: actionAllIn ?? this.actionAllIn,
      buttonSheen: buttonSheen ?? this.buttonSheen,
      potText: potText ?? this.potText,
      potBorder: potBorder ?? this.potBorder,
      chipBet: chipBet ?? this.chipBet,
      dealerChip: dealerChip ?? this.dealerChip,
      chipWhite: chipWhite ?? this.chipWhite,
      chipRed: chipRed ?? this.chipRed,
      chipBlue: chipBlue ?? this.chipBlue,
      chipGreen: chipGreen ?? this.chipGreen,
      badgeAllIn: badgeAllIn ?? this.badgeAllIn,
      badgeFold: badgeFold ?? this.badgeFold,
      winnerGlow: winnerGlow ?? this.winnerGlow,
      allInGlow: allInGlow ?? this.allInGlow,
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
      feltHighlight: Color.lerp(feltHighlight, other.feltHighlight, t)!,
      tableBorder: Color.lerp(tableBorder, other.tableBorder, t)!,
      goldPrimary: Color.lerp(goldPrimary, other.goldPrimary, t)!,
      goldLight: Color.lerp(goldLight, other.goldLight, t)!,
      goldDark: Color.lerp(goldDark, other.goldDark, t)!,
      cardFace: Color.lerp(cardFace, other.cardFace, t)!,
      cardFaceWhite: Color.lerp(cardFaceWhite, other.cardFaceWhite, t)!,
      cardPlaceholder: Color.lerp(cardPlaceholder, other.cardPlaceholder, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardSheen: Color.lerp(cardSheen, other.cardSheen, t)!,
      cardBackPrimary: Color.lerp(cardBackPrimary, other.cardBackPrimary, t)!,
      cardBackSecondary: Color.lerp(cardBackSecondary, other.cardBackSecondary, t)!,
      suitRed: Color.lerp(suitRed, other.suitRed, t)!,
      suitBlack: Color.lerp(suitBlack, other.suitBlack, t)!,
      seatBackground: Color.lerp(seatBackground, other.seatBackground, t)!,
      seatActive: Color.lerp(seatActive, other.seatActive, t)!,
      seatActiveBorder: Color.lerp(seatActiveBorder, other.seatActiveBorder, t)!,
      seatActiveGlow: Color.lerp(seatActiveGlow, other.seatActiveGlow, t)!,
      seatBorderDefault: Color.lerp(seatBorderDefault, other.seatBorderDefault, t)!,
      seatBorderAllIn: Color.lerp(seatBorderAllIn, other.seatBorderAllIn, t)!,
      turnIndicatorGlow: Color.lerp(turnIndicatorGlow, other.turnIndicatorGlow, t)!,
      actionFold: Color.lerp(actionFold, other.actionFold, t)!,
      actionCheck: Color.lerp(actionCheck, other.actionCheck, t)!,
      actionCall: Color.lerp(actionCall, other.actionCall, t)!,
      actionBet: Color.lerp(actionBet, other.actionBet, t)!,
      actionAllIn: Color.lerp(actionAllIn, other.actionAllIn, t)!,
      buttonSheen: Color.lerp(buttonSheen, other.buttonSheen, t)!,
      potText: Color.lerp(potText, other.potText, t)!,
      potBorder: Color.lerp(potBorder, other.potBorder, t)!,
      chipBet: Color.lerp(chipBet, other.chipBet, t)!,
      dealerChip: Color.lerp(dealerChip, other.dealerChip, t)!,
      chipWhite: Color.lerp(chipWhite, other.chipWhite, t)!,
      chipRed: Color.lerp(chipRed, other.chipRed, t)!,
      chipBlue: Color.lerp(chipBlue, other.chipBlue, t)!,
      chipGreen: Color.lerp(chipGreen, other.chipGreen, t)!,
      badgeAllIn: Color.lerp(badgeAllIn, other.badgeAllIn, t)!,
      badgeFold: Color.lerp(badgeFold, other.badgeFold, t)!,
      winnerGlow: Color.lerp(winnerGlow, other.winnerGlow, t)!,
      allInGlow: Color.lerp(allInGlow, other.allInGlow, t)!,
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
