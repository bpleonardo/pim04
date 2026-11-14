import 'package:flutter/material.dart';

class AppTheme {
  static final mode = ValueNotifier(ThemeMode.light);

  static ColorScheme _colors(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final foreground = dark ? Colors.white : Colors.black;
    final background = dark ? const Color(0xFF141414) : Colors.white;
    final container = dark ? const Color(0xFF303030) : const Color(0xFFE9E9E9);
    return ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.monochrome,
    ).copyWith(
      primary: foreground,
      onPrimary: background,
      primaryContainer: container,
      onPrimaryContainer: foreground,
      secondary: foreground,
      onSecondary: background,
      secondaryContainer: container,
      onSecondaryContainer: foreground,
      tertiary: foreground,
      onTertiary: background,
      tertiaryContainer: container,
      onTertiaryContainer: foreground,
      surface: background,
      onSurface: foreground,
      surfaceDim: dark ? const Color(0xFF101010) : const Color(0xFFE0E0E0),
      surfaceBright: dark ? const Color(0xFF383838) : Colors.white,
      surfaceContainerLowest: dark ? Colors.black : Colors.white,
      surfaceContainerLow:
          dark ? const Color(0xFF1C1C1C) : const Color(0xFFF7F7F7),
      surfaceContainer:
          dark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
      surfaceContainerHigh:
          dark ? const Color(0xFF292929) : const Color(0xFFE9E9E9),
      surfaceContainerHighest: container,
      onSurfaceVariant:
          dark ? const Color(0xFFD0D0D0) : const Color(0xFF454545),
      surfaceTint: Colors.transparent,
      outline: dark ? const Color(0xFFAAAAAA) : const Color(0xFF303030),
      outlineVariant: dark ? const Color(0xFF555555) : const Color(0xFFCCCCCC),
      inverseSurface: foreground,
      onInverseSurface: background,
      inversePrimary: background,
      errorContainer: container,
      onErrorContainer:
          dark ? const Color(0xFFFFB4AB) : const Color(0xFF780E0E),
    );
  }

  static ThemeData get dark {
    final colors = _colors(Brightness.dark);
    return ThemeData(
      colorScheme: colors,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
    );
  }

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: _colors(Brightness.light),
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

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Ativar modo claro' : 'Ativar modo escuro',
      onPressed: () =>
          AppTheme.mode.value = dark ? ThemeMode.light : ThemeMode.dark,
      icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
