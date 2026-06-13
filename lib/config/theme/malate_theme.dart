import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'malate_colors.dart';
import 'malate_color_extension.dart';
import 'malate_typography.dart';

class MalateTheme {
  MalateTheme._();

  static const double cardRadius = 14.0;
  static const double buttonRadius = 12.0;
  static const double buttonHeight = 56.0;
  static const double chipHeight = 44.0;

  // ── Dark Theme ──
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        ext: MalateColorExtension.dark,
        statusBarBrightness: Brightness.light,
      );

  // ── Light Theme ──
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        ext: MalateColorExtension.light,
        statusBarBrightness: Brightness.dark,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required MalateColorExtension ext,
    required Brightness statusBarBrightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: ext.midnight,
      extensions: [ext],
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: ext.midnight,
        primary: MalateColors.neonMint,
        secondary: MalateColors.cyberCyan,
        tertiary: MalateColors.electricAmber,
        error: MalateColors.hazardRed,
        onPrimary: ext.midnight,
        onSecondary: ext.midnight,
        onSurface: ext.textPrimary,
        onError: ext.midnight,
        surfaceContainerHighest: ext.gutter,
      ),
      fontFamily: 'Roboto',
      useMaterial3: true,

      appBarTheme: AppBarTheme(
        backgroundColor: ext.midnight,
        foregroundColor: ext.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: MalateTypography.headlineMedium.copyWith(
          color: ext.textPrimary,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusBarBrightness,
          systemNavigationBarColor: ext.midnight,
          systemNavigationBarIconBrightness: statusBarBrightness,
        ),
      ),

      cardTheme: CardThemeData(
        color: ext.asphalt,
        elevation: isDark ? 0 : 1,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: BorderSide(
            color: ext.sidewalk,
            width: 1,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MalateColors.neonMint,
          foregroundColor: ext.midnight,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          textStyle: MalateTypography.labelLarge,
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MalateColors.neonMint,
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonRadius),
          ),
          side: const BorderSide(color: MalateColors.neonMint, width: 1.5),
          textStyle: MalateTypography.labelLarge.copyWith(
            color: MalateColors.neonMint,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: MalateColors.cyberCyan,
          minimumSize: const Size(48, chipHeight),
          textStyle: MalateTypography.labelMedium,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ext.gutter,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        hintStyle: MalateTypography.bodyLarge.copyWith(
          color: ext.textMuted,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide: BorderSide(color: ext.sidewalk),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          borderSide:
              const BorderSide(color: MalateColors.cyberCyan, width: 1.5),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: ext.asphalt,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        dragHandleColor: ext.concrete,
        dragHandleSize: const Size(40, 4),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: MalateColors.neonMint,
        foregroundColor: ext.midnight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
      ),

      iconTheme: IconThemeData(
        color: ext.textSecondary,
        size: 24,
      ),

      dividerTheme: DividerThemeData(
        color: ext.sidewalk,
        thickness: 1,
        space: 1,
      ),

      chipTheme: ChipThemeData(
        backgroundColor: ext.gutter,
        selectedColor: MalateColors.neonMint.withValues(alpha: 0.15),
        side: BorderSide(color: ext.sidewalk),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: MalateTypography.labelMedium,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: ext.gutter,
        contentTextStyle: MalateTypography.bodyMedium.copyWith(
          color: ext.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
