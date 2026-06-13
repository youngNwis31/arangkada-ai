import 'package:flutter/material.dart';

class MalateColorExtension extends ThemeExtension<MalateColorExtension> {
  final Color midnight;
  final Color asphalt;
  final Color gutter;
  final Color sidewalk;
  final Color concrete;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textDisabled;

  const MalateColorExtension({
    required this.midnight,
    required this.asphalt,
    required this.gutter,
    required this.sidewalk,
    required this.concrete,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textDisabled,
  });

  static const dark = MalateColorExtension(
    midnight: Color(0xFF0D0D0D),
    asphalt: Color(0xFF141414),
    gutter: Color(0xFF1A1A1A),
    sidewalk: Color(0xFF242424),
    concrete: Color(0xFF2E2E2E),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFAAAAAA),
    textMuted: Color(0xFF666666),
    textDisabled: Color(0xFF444444),
  );

  static const light = MalateColorExtension(
    midnight: Color(0xFFFFFFFF),
    asphalt: Color(0xFFF5F5F5),
    gutter: Color(0xFFEEEEEE),
    sidewalk: Color(0xFFE0E0E0),
    concrete: Color(0xFFD5D5D5),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF555555),
    textMuted: Color(0xFF999999),
    textDisabled: Color(0xFFBBBBBB),
  );

  @override
  ThemeExtension<MalateColorExtension> copyWith({
    Color? midnight,
    Color? asphalt,
    Color? gutter,
    Color? sidewalk,
    Color? concrete,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textDisabled,
  }) =>
      MalateColorExtension(
        midnight: midnight ?? this.midnight,
        asphalt: asphalt ?? this.asphalt,
        gutter: gutter ?? this.gutter,
        sidewalk: sidewalk ?? this.sidewalk,
        concrete: concrete ?? this.concrete,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted: textMuted ?? this.textMuted,
        textDisabled: textDisabled ?? this.textDisabled,
      );

  @override
  ThemeExtension<MalateColorExtension> lerp(
      covariant ThemeExtension<MalateColorExtension>? other, double t) {
    if (other is! MalateColorExtension) return this;
    return MalateColorExtension(
      midnight: Color.lerp(midnight, other.midnight, t)!,
      asphalt: Color.lerp(asphalt, other.asphalt, t)!,
      gutter: Color.lerp(gutter, other.gutter, t)!,
      sidewalk: Color.lerp(sidewalk, other.sidewalk, t)!,
      concrete: Color.lerp(concrete, other.concrete, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
    );
  }
}
