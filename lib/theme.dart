import 'package:flutter/material.dart';

class AppTheme {
  static const Color bloodRed = Color(0xFF8B0000);
  static ThemeData get dark {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: bloodRed,
      onPrimary: Colors.white,
      secondary: bloodRed,
      onSecondary: Colors.white,
      error: Colors.red,
      onError: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      surface: Color(0xFF121212),
      onSurface: Colors.white,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: bloodRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bloodRed),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: bloodRed, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF121212),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: bloodRed, width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
