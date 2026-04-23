import 'dart:convert';

import 'package:flutter/material.dart';

enum CardBackStyle { classicBlue, royalCrimson, noirGold, emeraldPattern }

enum TableFeltColor { classicGreen, midnightBlue, royalPurple, charcoalElite }

enum SoundProfile { off, subtle, full }

typedef FeltOverrides = ({
  Color feltCenter,
  Color feltEdge,
  Color feltHighlight,
});

typedef CardBackOverrides = ({
  Color cardBackPrimary,
  Color cardBackSecondary,
});

class PersonalizationSettings {
  static const storageKey = 'personalization_v1';

  final CardBackStyle cardBack;
  final TableFeltColor felt;
  final SoundProfile sound;

  const PersonalizationSettings({
    required this.cardBack,
    required this.felt,
    required this.sound,
  });

  const PersonalizationSettings.defaults()
      : cardBack = CardBackStyle.classicBlue,
        felt = TableFeltColor.classicGreen,
        sound = SoundProfile.subtle;

  PersonalizationSettings copyWith({
    CardBackStyle? cardBack,
    TableFeltColor? felt,
    SoundProfile? sound,
  }) {
    return PersonalizationSettings(
      cardBack: cardBack ?? this.cardBack,
      felt: felt ?? this.felt,
      sound: sound ?? this.sound,
    );
  }

  Map<String, dynamic> toJson() => {
        'cardBack': cardBack.name,
        'felt': felt.name,
        'sound': sound.name,
      };

  String encode() => jsonEncode(toJson());

  static PersonalizationSettings? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is! Map<String, dynamic>) return null;
      return PersonalizationSettings(
        cardBack: _parseEnum(
          CardBackStyle.values,
          map['cardBack'],
          CardBackStyle.classicBlue,
        ),
        felt: _parseEnum(
          TableFeltColor.values,
          map['felt'],
          TableFeltColor.classicGreen,
        ),
        sound: _parseEnum(
          SoundProfile.values,
          map['sound'],
          SoundProfile.subtle,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static T _parseEnum<T extends Enum>(List<T> values, Object? raw, T fallback) {
    if (raw is! String) return fallback;
    for (final v in values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  static FeltOverrides feltOverrides(TableFeltColor felt) {
    switch (felt) {
      case TableFeltColor.classicGreen:
        return (
          feltCenter: const Color(0xFF1B5E20),
          feltEdge: const Color(0xFF0D3B12),
          feltHighlight: const Color(0xFF267029),
        );
      case TableFeltColor.midnightBlue:
        return (
          feltCenter: const Color(0xFF0D2A52),
          feltEdge: const Color(0xFF061429),
          feltHighlight: const Color(0xFF1E3F72),
        );
      case TableFeltColor.royalPurple:
        return (
          feltCenter: const Color(0xFF4A148C),
          feltEdge: const Color(0xFF210046),
          feltHighlight: const Color(0xFF6A1B9A),
        );
      case TableFeltColor.charcoalElite:
        return (
          feltCenter: const Color(0xFF212121),
          feltEdge: const Color(0xFF0B0B0B),
          feltHighlight: const Color(0xFFD4AF37),
        );
    }
  }

  static CardBackOverrides cardBackOverrides(CardBackStyle style) {
    switch (style) {
      case CardBackStyle.classicBlue:
        return (
          cardBackPrimary: const Color(0xFF1A237E),
          cardBackSecondary: const Color(0xFF283593),
        );
      case CardBackStyle.royalCrimson:
        return (
          cardBackPrimary: const Color(0xFF8B0000),
          cardBackSecondary: const Color(0xFFB71C1C),
        );
      case CardBackStyle.noirGold:
        return (
          cardBackPrimary: const Color(0xFF101010),
          cardBackSecondary: const Color(0xFFD4AF37),
        );
      case CardBackStyle.emeraldPattern:
        return (
          cardBackPrimary: const Color(0xFF0D3B12),
          cardBackSecondary: const Color(0xFF267029),
        );
    }
  }
}
