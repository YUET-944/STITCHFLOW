import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Palette ────────────────────────────────────────────────────────
  static const Color primaryDeepNavy  = Color(0xFF0B1120);
  static const Color navyMid          = Color(0xFF0F172A);
  static const Color slateGrey        = Color(0xFF334155);
  static const Color softAmber        = Color(0xFFF59E0B);
  static const Color premiumGold      = Color(0xFFD4AF37);
  static const Color accentGold       = Color(0xFFD4AF37); // alias for premiumGold
  static const Color successGreen     = Color(0xFF10B981);
  static const Color errorRed         = Color(0xFFEF4444);
  static const Color surfaceWhite     = Color(0xFFFFFFFF);
  static const Color backgroundLight  = Color(0xFFF1F5F9);
  static const Color cardWhite        = Color(0xFFFFFFFF);

  // Dark-mode equivalents
  static const Color darkBg           = Color(0xFF060D1A);
  static const Color darkSurface      = Color(0xFF0F1E35);
  static const Color darkCard         = Color(0xFF162133);
  static const Color darkDivider      = Color(0xFF1E2D45);

  // ── Typography ───────────────────────────────────────────────────────────
  static TextTheme get _textTheme => GoogleFonts.outfitTextTheme().copyWith(
    displayLarge: GoogleFonts.outfit(
        fontSize: 56, fontWeight: FontWeight.w800, letterSpacing: -2, height: 1.1),
    displayMedium: GoogleFonts.outfit(
        fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.5),
    displaySmall: GoogleFonts.outfit(
        fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -1),
    headlineLarge: GoogleFonts.outfit(
        fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
    headlineMedium: GoogleFonts.outfit(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3),
    headlineSmall: GoogleFonts.outfit(
        fontSize: 20, fontWeight: FontWeight.w600),
    titleLarge: GoogleFonts.outfit(
        fontSize: 18, fontWeight: FontWeight.w600),
    titleMedium: GoogleFonts.outfit(
        fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.1),
    titleSmall: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w400),
    labelLarge: GoogleFonts.outfit(
        fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.2),
    labelSmall: GoogleFonts.outfit(
        fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5),
  );

  // ── Light Theme ──────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: _textTheme,
      colorScheme: const ColorScheme.light(
        primary:           primaryDeepNavy,
        onPrimary:         surfaceWhite,
        secondary:         softAmber,
        onSecondary:       primaryDeepNavy,
        tertiary:          premiumGold,
        onTertiary:        primaryDeepNavy,
        surface:           cardWhite,
        onSurface:         primaryDeepNavy,
        error:             errorRed,
        surfaceContainerHighest: backgroundLight,
      ),
      scaffoldBackgroundColor: backgroundLight,

      // ── AppBar ──
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceWhite,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.05),
        iconTheme: const IconThemeData(color: primaryDeepNavy),
        titleTextStyle: GoogleFonts.outfit(
          color: primaryDeepNavy,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),

      // ── Elevated Button ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDeepNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5),
        ),
      ),

      // ── Outlined Button ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDeepNavy,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          side: const BorderSide(color: primaryDeepNavy, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      // ── Text Button ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: softAmber,
          textStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),

      // ── Input Decoration ──
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: premiumGold, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintStyle:
            GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 15),
        prefixIconColor: Colors.grey.shade400,
      ),

      // ── Card ──
      cardTheme: CardThemeData(
        color: cardWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),

      // ── Chip ──
      chipTheme: ChipThemeData(
        backgroundColor: backgroundLight,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        side: BorderSide.none,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: _textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      colorScheme: const ColorScheme.dark(
        primary:    premiumGold,
        onPrimary:  darkBg,
        secondary:  softAmber,
        surface:    darkSurface,
        onSurface:  Colors.white,
        error:      errorRed,
        surfaceContainerHighest: darkCard,
      ),
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        elevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
