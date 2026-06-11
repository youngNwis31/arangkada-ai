import 'package:flutter/material.dart';
import 'malate_colors.dart';

class MalateTypography {
  MalateTypography._();

  static const String _fontFamily = 'Roboto';

  // ── Display — Hero numbers, ETA countdown ──
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    color: MalateColors.textPrimary,
    letterSpacing: -1.5,
    height: 1.1,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: MalateColors.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  // ── Headlines — Screen titles, section headers ──
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: MalateColors.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: MalateColors.textPrimary,
    letterSpacing: 0.15,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: MalateColors.textPrimary,
  );

  // ── Body — Descriptions, directions ──
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: MalateColors.textSecondary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: MalateColors.textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: MalateColors.textMuted,
    height: 1.3,
  );

  // ── Labels — Buttons, chips, badges ──
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: MalateColors.midnight,
    letterSpacing: 1.2,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: MalateColors.textSecondary,
    letterSpacing: 0.8,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: MalateColors.textMuted,
    letterSpacing: 1.0,
  );

  // ── Special — Neon accent text ──
  static TextStyle neonAccent(Color color) => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 1.5,
      );
}
