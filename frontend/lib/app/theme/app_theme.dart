import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.black,
                brightness: Brightness.light,
                dynamicSchemeVariant: DynamicSchemeVariant.monochrome)
            .copyWith(
          primary: Colors.black,
          secondary: Colors.black,
          secondaryContainer: const Color(0xFFE9EDF0),
          onSecondaryContainer: Colors.black,
          outline: const Color(0xFF303030),
          errorContainer: const Color(0xFFF1F1F1),
          onErrorContainer: const Color(0xFF780E0E),
        ),
        scaffoldBackgroundColor: Colors.white,
        chipTheme: const ChipThemeData(
          backgroundColor: Colors.white,
          selectedColor: Color(0xFFE9EDF0),
          disabledColor: Color(0xFFF5F5F5),
          side: BorderSide(color: Color(0xFF777777)),
          labelStyle: TextStyle(color: Colors.black),
          checkmarkColor: Colors.black,
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          scrolledUnderElevation: 0,
          shape: Border(bottom: BorderSide(color: Color(0xFF303030))),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFF303030)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black, foregroundColor: Colors.white)),
      );
}
