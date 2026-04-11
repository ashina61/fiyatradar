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
  static const Color foam = Color.fromARGB(255, 245, 241, 237);
  static const Color cream = Color.fromARGB(255, 250, 246, 242);
  static const Color crema = Color.fromARGB(255, 231, 222, 212);
  static const Color accent = Color.fromARGB(255, 196, 138, 90);
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
        borderRadius: FRRadii.lg,
        borderSide: const BorderSide(color: ProtoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: FRRadii.lg,
        borderSide: const BorderSide(color: ProtoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: FRRadii.lg,
        borderSide: const BorderSide(color: ProtoColors.tan),
      ),
    ),
  );
}
