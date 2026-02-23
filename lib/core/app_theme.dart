import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Milky Palette
  static const Color milkyWhite =
      Color(0xFFFDFDF9); // Soft, warm off-white surface
  static const Color brandBlueGreen =
      Color(0xFF2C6F81); // The requested blue-green
  static const Color softCream =
      Color(0xFFF4F4F0); // Comforting milky background
  static const Color safetyTeal = Color(0xFF3B818F); // Muted teal for badges
  static const Color alertRed = Color(0xFFDC2626); // Emergency
  static const Color verifyGold =
      Color(0xFFB45309); // Darker gold for light mode text

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: brandBlueGreen,
      scaffoldBackgroundColor: softCream,
      colorScheme: const ColorScheme.light(
        primary: brandBlueGreen,
        secondary: safetyTeal,
        surface: milkyWhite,
        error: alertRed,
        tertiary: verifyGold,
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF0F172A)),
        headlineMedium: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Color(0xFF0F172A)),
        titleLarge: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            color: Color(0xFF334155)),
      ),
      cardTheme: CardThemeData(
        color: milkyWhite,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.black.withOpacity(0.03))),
      ),
    );
  }
}
