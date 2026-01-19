import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Surf vibe minimal palette (max 5 tokens)
  static const Color oceanBlue = Color(0xFF0A7CFF); // Primary - buttons, links
  static const Color seafoamGreen = Color(0xFF26A69A); // Success - great conditions
  static const Color sand = Color(0xFFF5F1E8); // Background - off-white
  static const Color coral = Color(0xFFFF8A80); // Warning/bad - unsafe conditions
  static const Color slateGray = Color(0xFF475569); // Text - readable gray
  
  // Legacy aliases for compatibility
  static const Color ocean = oceanBlue;
  static const Color primaryBlue = oceanBlue;
  static const Color turquoise = seafoamGreen;
  static const Color sandBeige = sand;
  static const Color darkBlue = Color(0xFF1E293B);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF8F9FA);
  static const Color darkGray = slateGray;
  
  // Status colors (surf-style)
  static const Color greatGreen = seafoamGreen; // Seafoam for great
  static const Color okYellow = Color(0xFFFFB74D); // Warm for ok  
  static const Color marginalOrange = Color(0xFFFF8A65); // Coral tint for marginal
  static const Color badRed = coral; // Coral for bad

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: turquoise,
        surface: white,
        background: lightGray,
      ),
      scaffoldBackgroundColor: lightGray,
      appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkBlue,
          letterSpacing: 1.2,
        ),
        iconTheme: const IconThemeData(color: darkBlue),
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkBlue,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: darkBlue,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          color: darkGray,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          color: darkGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          textStyle: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: white,
      ),
    );
  }

  static Color getStatusColor(String label) {
    switch (label.toLowerCase()) {
      case 'great':
        return greatGreen;
      case 'ok':
        return okYellow;
      case 'marginal':
        return marginalOrange;
      case 'bad':
        return badRed;
      default:
        return darkGray;
    }
  }

  static String getStatusEmoji(String label) {
    switch (label.toLowerCase()) {
      case 'great':
        return '🏄‍♂️';
      case 'ok':
        return '🌊';
      case 'marginal':
        return '⚠️';
      case 'bad':
        return '🚫';
      default:
        return '🌊';
    }
  }
}
