import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 2027 Ultra-Modern B2B Design System for Riforni.
/// Inspired by Linear, Apple iOS 18/19, and modern culinary tech.
class AppTheme {
  // ── 2027 Core Color Tokens ─────────────────────────────────────────
  // Primary: Electric Royal Blue / Cobalt (crisp, professional, authoritative)
  static const Color primary        = Color(0xFF2563EB);
  static const Color primaryDark    = Color(0xFF1D4ED8);
  static const Color primaryLight   = Color(0xFF60A5FA);

  // Backward-compatibility alias so existing screens don't break
  static const Color terracotta     = Color(0xFF2563EB); 

  // Slate Neutral Scale (Tailwind 2027 Zinc / Slate)
  static const Color bgCanvas       = Color(0xFFF8FAFC); // Slate-50
  static const Color bgSurface      = Color(0xFFFFFFFF); // Pure White
  static const Color borderSubtle   = Color(0xFFE2E8F0); // Slate-200
  static const Color borderMuted    = Color(0xFFF1F5F9); // Slate-100

  // Typography
  static const Color textMain       = Color(0xFF0F172A); // Slate-900
  static const Color textSecondary  = Color(0xFF475569); // Slate-600
  static const Color textMuted      = Color(0xFF94A3B8); // Slate-400
  static const Color darkSlate      = Color(0xFF0F172A);
  static const Color background     = Color(0xFFF8FAFC);

  // Semantic Status Colors
  static const Color statusSuccess  = Color(0xFF10B981); // Emerald-500
  static const Color whatsappGreen  = Color(0xFF25D366); // Official WhatsApp
  static const Color statusWarning  = Color(0xFFF59E0B); // Amber-500
  static const Color statusDanger   = Color(0xFFEF4444); // Rose-500

  // ── Diffused Ambient Shadows ───────────────────────────────────────
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x040F172A),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x180F172A),
      blurRadius: 28,
      offset: Offset(0, 12),
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x402563EB),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  // ── Color Schemes ──────────────────────────────────────────────────
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFEFF6FF),
    onPrimaryContainer: Color(0xFF1E40AF),
    secondary: Color(0xFF0F172A),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFF1F5F9),
    onSecondaryContainer: Color(0xFF0F172A),
    tertiary: Color(0xFF0D9488),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFCCFBF1),
    onTertiaryContainer: Color(0xFF115E59),
    error: statusDanger,
    onError: Colors.white,
    surface: bgSurface,
    onSurface: textMain,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: bgCanvas,
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    outline: borderSubtle,
    outlineVariant: borderMuted,
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF0F172A),
    primaryContainer: Color(0xFF1E3A8A),
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: Color(0xFF94A3B8),
    onSecondary: Color(0xFF0F172A),
    surface: Color(0xFF0B0F19),
    onSurface: Color(0xFFF8FAFC),
    surfaceContainer: Color(0xFF131B2E),
    surfaceContainerHigh: Color(0xFF1E293B),
    error: Color(0xFFF87171),
    onError: Color(0xFF450A0A),
    outline: Color(0xFF334155),
  );

  // ── Typography ─────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color main, Color muted) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.15,
        color: main,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.25,
        color: main,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.3,
        color: main,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.35,
        color: main,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        height: 1.4,
        color: main,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.5,
        color: main,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
        height: 1.45,
        color: muted,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.3,
        color: main,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        height: 1.3,
        color: muted,
      ),
    );
  }

  // ── Light Theme ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      scaffoldBackgroundColor: bgCanvas,
      textTheme: _buildTextTheme(textMain, textSecondary),

      appBarTheme: AppBarTheme(
        backgroundColor: bgCanvas,
        foregroundColor: textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textMain,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.6,
        ),
        iconTheme: const IconThemeData(color: textMain, size: 22),
      ),

      cardTheme: CardTheme(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: borderMuted, width: 1),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textMain,
          elevation: 0,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: borderSubtle, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: borderMuted),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: textMuted,
        ),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: bgSurface,
        modalBackgroundColor: bgSurface,
        elevation: 16,
        showDragHandle: true,
        dragHandleColor: borderSubtle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
  static ThemeData get theme => lightTheme;
}
