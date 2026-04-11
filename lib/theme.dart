import 'package:flutter/material.dart';

import 'widgets/prototype_ui.dart';

/// Legacy compatibility palette.
/// Kept for older screens that have not yet been migrated to prototype_ui.
class CoffeeColors {
  static const Color espresso = ProtoColors.bgPrimary;
  static const Color darkRoast = ProtoColors.bgSecondary;
  static const Color mocha = ProtoColors.surface;
  static const Color cocoa = ProtoColors.textSubtle;
  static const Color caramel = ProtoColors.tan;
  static const Color latte = ProtoColors.tanLight;
  static const Color foam = Color(0xFFF5F1ED);
  static const Color cream = Color(0xFFFAF6F2);
  static const Color crema = Color(0xFFE7DED4);
  static const Color accent = Color(0xFFC48A5A);
  static const Color success = ProtoColors.success;
  static const Color danger = ProtoColors.danger;
}

ThemeData buildCoffeeTheme() {
  const scheme = ColorScheme.dark(
    primary: ProtoColors.tan,
    onPrimary: ProtoColors.bgPrimary,
    secondary: ProtoColors.tanLight,
    onSecondary: ProtoColors.bgPrimary,
    surface: ProtoColors.surface,
    onSurface: ProtoColors.textPrimary,
    error: ProtoColors.danger,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: ProtoColors.bgPrimary,
    appBarTheme: const AppBarTheme(
      backgroundColor: ProtoColors.bgPrimary,
      foregroundColor: ProtoColors.textPrimary,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: ProtoColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ProtoColors.surface,
      hintStyle: const TextStyle(color: ProtoColors.textSubtle),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ProtoRadius.lg),
        borderSide: const BorderSide(color: ProtoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ProtoRadius.lg),
        borderSide: const BorderSide(color: ProtoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ProtoRadius.lg),
        borderSide: const BorderSide(color: ProtoColors.tan),
      ),
    ),
  );
}
