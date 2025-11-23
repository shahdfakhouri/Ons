// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Palette you chose
  static const Color deepNavy = Color(0xFF313647);
  static const Color denim    = Color(0xFF435663);
  static const Color sage     = Color(0xFFA3B087);
  static const Color cream    = Color(0xFFFFF8D4);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: denim,
        primary: denim,
        secondary: sage,
        surface: cream,
        onPrimary: Colors.white,
        onSecondary: deepNavy,
        onSurface: deepNavy,
        onBackground: deepNavy,
      ),
      scaffoldBackgroundColor: cream,
    );

    return base.copyWith(
      // ✅ Global font – now ALL Text() uses Playfair by default
      textTheme: GoogleFonts.playfairDisplayTextTheme(base.textTheme).apply(
        bodyColor: deepNavy,
        displayColor: deepNavy,
      ),

      cardTheme: CardThemeData(
        // ignore: deprecated_member_use
        color: Colors.white.withOpacity(0.9),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: denim,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),
    );
  }
}
