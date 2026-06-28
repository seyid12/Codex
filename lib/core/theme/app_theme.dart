import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get synthwaveTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0B1A), // Deep dark purple
      primaryColor: const Color(0xFFFF007F), // Neon Pink
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF007F), // Neon Pink
        secondary: Color(0xFF00F0FF), // Neon Cyan
        surface: Color(0xFF1E1533), // Slightly lighter purple for cards
        error: Color(0xFFFF3333),
      ),
      fontFamily: 'Roboto', // Placeholder, can be changed to a retro font later
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0B1A),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Color(0xFF00F0FF),
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          shadows: [
            Shadow(
              color: Color(0xFF00F0FF),
              blurRadius: 10,
            ),
          ],
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF007F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          shadowColor: const Color(0xFFFF007F).withOpacity(0.8),
          elevation: 8,
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1E1533),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00F0FF), width: 1),
        ),
        elevation: 10,
        shadowColor: const Color(0xFF00F0FF).withOpacity(0.3),
      ),
    );
  }
}
