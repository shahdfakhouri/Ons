// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color deepNavy = Color(0xFF313647);
  static const Color denim = Color(0xFF435663);
  static const Color sage = Color(0xFFA3B087);
  static const Color cream = Color(0xFFFFF8D4);

  static ThemeData get lightTheme {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: denim,
        brightness: Brightness.light,
        primary: denim,
        secondary: sage,
        surface: cream,
        background: cream,
        onPrimary: Colors.white,
        onSecondary: deepNavy,
        onSurface: deepNavy,
        onBackground: deepNavy,
      ),
      scaffoldBackgroundColor: cream,
    );

    final textTheme = GoogleFonts.playfairDisplayTextTheme(base.textTheme).apply(
      bodyColor: deepNavy,
      displayColor: deepNavy,
    );

    return base.copyWith(
      textTheme: textTheme,

      // ✅ AppBar looks cleaner on web
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: deepNavy,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: deepNavy,
        ),
      ),

      // ✅ Cards: soft border + subtle elevation
     cardTheme: CardThemeData(
  // ignore: deprecated_member_use
  color: Colors.white.withOpacity(0.92),
  elevation: 1,
  shadowColor: Colors.black.withOpacity(0.06),
  margin: const EdgeInsets.symmetric(vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(18),
    side: BorderSide(color: deepNavy.withOpacity(0.08)),
  ),
),


      // ✅ Inputs: consistent and nicer than default
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.95),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deepNavy.withOpacity(0.10)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: deepNavy.withOpacity(0.10)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: denim, width: 1.8),
        ),
        labelStyle: TextStyle(color: deepNavy.withOpacity(0.75)),
        hintStyle: TextStyle(color: deepNavy.withOpacity(0.45)),
      ),

      // ✅ Buttons: consistent height + rounded
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: denim,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepNavy,
          side: BorderSide(color: deepNavy.withOpacity(0.18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: denim,
          textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // ✅ Chips used in alerts/status filters
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white.withOpacity(0.9),
        labelStyle: TextStyle(color: deepNavy.withOpacity(0.85)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: deepNavy.withOpacity(0.10)),
        ),
      ),

      // ✅ NavRail (your sidebar in screenshot)
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cream,
        selectedIconTheme: const IconThemeData(color: denim),
        unselectedIconTheme: IconThemeData(color: deepNavy.withOpacity(0.55)),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: denim,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: deepNavy.withOpacity(0.65),
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: denim.withOpacity(0.14),
      ),

      // ✅ Bottom nav (mobile)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cream,
        indicatorColor: denim.withOpacity(0.14),
        labelTextStyle: MaterialStateProperty.all(
          textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          final selected = states.contains(MaterialState.selected);
          return IconThemeData(
            color: selected ? denim : deepNavy.withOpacity(0.55),
          );
        }),
      ),

      // ✅ Dividers used near rail
      dividerTheme: DividerThemeData(
        color: deepNavy.withOpacity(0.10),
        thickness: 1,
        space: 1,
      ),

      // ✅ Snackbars consistent
      snackBarTheme: SnackBarThemeData(
        backgroundColor: deepNavy,
        contentTextStyle: TextStyle(color: Colors.white.withOpacity(0.95)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
