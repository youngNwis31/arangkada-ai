import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'malate_colors.dart';
import 'malate_typography.dart';

class MalateTheme {
  MalateTheme._();

  static const double cardRadius = 14.0;
  static const double buttonRadius = 12.0;
  static const double buttonHeight = 56.0; // Glove-friendly oversized targets
  static const double chipHeight = 44.0;

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: MalateColors.midnight,
        colorScheme: const ColorScheme.dark(
          surface: MalateColors.midnight,
          primary: MalateColors.neonMint,
          secondary: MalateColors.cyberCyan,
          tertiary: MalateColors.electricAmber,
          error: MalateColors.hazardRed,
          onPrimary: MalateColors.midnight,
          onSecondary: MalateColors.midnight,
          onSurface: MalateColors.textPrimary,
          onError: MalateColors.midnight,
          surfaceContainerHighest: MalateColors.gutter,
        ),
        fontFamily: 'Roboto',
        useMaterial3: true,

        // ── App Bar ──
        appBarTheme: const AppBarTheme(
          backgroundColor: MalateColors.midnight,
          foregroundColor: MalateColors.textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleTextStyle: MalateTypography.headlineMedium,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: MalateColors.midnight,
          ),
        ),

        // ── Cards — Boxy streetwear aesthetic ──
        cardTheme: CardThemeData(
          color: MalateColors.asphalt,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            side: const BorderSide(
              color: MalateColors.sidewalk,
              width: 1,
            ),
          ),
        ),

        // ── Elevated Buttons — Neon mint primary ──
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MalateColors.neonMint,
            foregroundColor: MalateColors.midnight,
            minimumSize: const Size(double.infinity, buttonHeight),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            textStyle: MalateTypography.labelLarge,
            elevation: 0,
          ),
        ),

        // ── Outlined Buttons ──
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

        // ── Text Buttons ──
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: MalateColors.cyberCyan,
            minimumSize: const Size(48, chipHeight),
            textStyle: MalateTypography.labelMedium,
          ),
        ),

        // ── Input Fields ──
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: MalateColors.gutter,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          hintStyle: MalateTypography.bodyLarge.copyWith(
            color: MalateColors.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide: const BorderSide(color: MalateColors.sidewalk),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(cardRadius),
            borderSide:
                const BorderSide(color: MalateColors.cyberCyan, width: 1.5),
          ),
        ),

        // ── Bottom Sheet ──
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: MalateColors.asphalt,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          dragHandleColor: MalateColors.concrete,
          dragHandleSize: Size(40, 4),
        ),

        // ── Floating Action Button ──
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: MalateColors.neonMint,
          foregroundColor: MalateColors.midnight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),

        // ── Icon ──
        iconTheme: const IconThemeData(
          color: MalateColors.textSecondary,
          size: 24,
        ),

        // ── Divider ──
        dividerTheme: const DividerThemeData(
          color: MalateColors.sidewalk,
          thickness: 1,
          space: 1,
        ),

        // ── Chip ──
        chipTheme: ChipThemeData(
          backgroundColor: MalateColors.gutter,
          selectedColor: MalateColors.neonMint.withValues(alpha: 0.15),
          side: const BorderSide(color: MalateColors.sidewalk),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          labelStyle: MalateTypography.labelMedium,
        ),

        // ── Snackbar ──
        snackBarTheme: SnackBarThemeData(
          backgroundColor: MalateColors.gutter,
          contentTextStyle: MalateTypography.bodyMedium.copyWith(
            color: MalateColors.textPrimary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
