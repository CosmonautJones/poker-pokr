import 'package:flutter/material.dart';
import 'package:poker_trainer/core/theme/poker_theme.dart';

final appTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorSchemeSeed: const Color(0xFF2E7D32), // poker green
  extensions: const [PokerTheme.dark],
  cardTheme: const CardThemeData(
    elevation: 2,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: true,
    elevation: 0,
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
