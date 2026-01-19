import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Surf vibe minimal palette (updated)
  static const Color oceanDeep = Color(0xFF0D3B66); // Ocean Deep - titles
  static const Color seafoamGreen = Color(0xFF42C2A1); // Seafoam - accents, success
  static const Color sand = Color(0xFFF4ECD8); // Sand - overlays, backgrounds
  static const Color lightSky = Color(0xFFA9E3F4); // Light Sky - subtle accents
  static const Color coralAccent = Color(0xFFFF6B6B); // Coral - CTAs, warnings
  
  // Legacy aliases for compatibility
  static const Color oceanBlue = oceanDeep;
  static const Color coral = coralAccent;
  static const Color slateGray = Color(0xFF475569); // Text - readable gray
  static const Color primaryBlue = oceanDeep;
  static const Color turquoise = seafoamGreen;
  static const Color sandBeige = sand;
  static const Color ocean = oceanDeep;
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
        seedColor: oceanDeep,
        primary: oceanDeep,
        secondary: seafoamGreen,
        surface: white,
        background: sand,
      ),
      scaffoldBackgroundColor: sand,
        appBarTheme: AppBarTheme(
        backgroundColor: white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.pacifico(
          fontSize: 24,
          color: oceanDeep,
        ),
        iconTheme: const IconThemeData(color: oceanDeep),
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.pacifico(
          fontSize: 32,
          color: oceanDeep,
        ),
        displayMedium: GoogleFonts.pacifico(
          fontSize: 24,
          color: oceanDeep,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: slateGray,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: slateGray,
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
          textStyle: GoogleFonts.inter(
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
