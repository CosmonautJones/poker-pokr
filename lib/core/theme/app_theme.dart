import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: 'Inter',
  colorSchemeSeed: const Color(0xFF2E7D32), // poker green
  extensions: const [PokerTheme.dark],
  textTheme: const TextTheme(
    displayLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    displayMedium: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    displaySmall: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    headlineLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    headlineMedium: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    headlineSmall: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    titleLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    titleMedium: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    titleSmall: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    bodyLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    bodyMedium: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    bodySmall: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    labelLarge: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    labelMedium: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
    labelSmall: TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
  ),
  navigationBarTheme: NavigationBarThemeData(
    indicatorColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
    backgroundColor: const Color(0xFF121212),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFFD4AF37));
      }
      return const IconThemeData(color: Color(0xB3FFFFFF));
    }),
  ),
  tabBarTheme: const TabBarThemeData(
    indicatorColor: Color(0xFFD4AF37),
    labelColor: Color(0xFFD4AF37),
    unselectedLabelColor: Color(0xB3FFFFFF),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  inputDecorationTheme: const InputDecorationTheme(
    filled: true,
    border: OutlineInputBorder(),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 48),
    ),
  ),
);
