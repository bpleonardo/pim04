import 'package:flutter/material.dart';

class AppTheme {
  static const black = Color(0xFF111111);
  static const white = Color(0xFFFFFFFF);
  static const gray = Color(0xFFF5F5F5);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: black,
      brightness: Brightness.light,
      primary: black,
      onPrimary: white,
      surface: white,
      onSurface: black,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: white,
      appBarTheme: const AppBarTheme(
        backgroundColor: white,
        foregroundColor: black,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: gray,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
