import 'package:flutter/material.dart';
import 'malate_color_extension.dart';

class MalateColors {
  MalateColors._();

  static MalateColorExtension of(BuildContext context) =>
      Theme.of(context).extension<MalateColorExtension>()!;

  // ── Core Backgrounds (static fallbacks for non-context code) ──
  static const Color midnight = Color(0xFF0D0D0D);
  static const Color asphalt = Color(0xFF141414);
  static const Color gutter = Color(0xFF1A1A1A);
  static const Color sidewalk = Color(0xFF242424);
  static const Color concrete = Color(0xFF2E2E2E);

  // ── Neon Accents (same in both light and dark) ──
  static const Color neonMint = Color(0xFF00FF94);
  static const Color cyberCyan = Color(0xFF00E5FF);
  static const Color electricAmber = Color(0xFFFFB300);
  static const Color hazardRed = Color(0xFFFF3D3D);
  static const Color signalWhite = Color(0xFFF5F5F5);

  // ── Text Hierarchy (static fallbacks) ──
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textMuted = Color(0xFF666666);
  static const Color textDisabled = Color(0xFF444444);

  // ── Congestion Indicators ──
  static const Color trafficClear = neonMint;
  static const Color trafficModerate = electricAmber;
  static const Color trafficHeavy = hazardRed;

  // ── Semantic ──
  static const Color success = neonMint;
  static const Color warning = electricAmber;
  static const Color error = hazardRed;
  static const Color info = cyberCyan;

  // ── Neon Glow Helpers ──
  static List<BoxShadow> neonGlow(Color color, {double intensity = 0.4}) => [
        BoxShadow(
          color: color.withValues(alpha: intensity),
          blurRadius: 12,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: color.withValues(alpha: intensity * 0.5),
          blurRadius: 24,
          spreadRadius: 2,
        ),
      ];

  static List<BoxShadow> subtleGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.2),
          blurRadius: 8,
        ),
      ];
}
