import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.black, brightness: Brightness.light)
            .copyWith(
          primary: Colors.black,
          secondary: Colors.black,
          secondaryContainer: const Color(0xFFE9EDF0),
          onSecondaryContainer: Colors.black,
          outline: const Color(0xFF303030),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black, foregroundColor: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white)),
      );
}
