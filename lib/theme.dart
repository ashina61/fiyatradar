import 'package:flutter/material.dart';

/// Bitter coffee color palette for FiyatRadar.
class CoffeeColors {
  static const Color espresso = Color(0xFF2B1810); // darkest
  static const Color darkRoast = Color(0xFF3E2418);
  static const Color mocha = Color(0xFF5C3A2E);
  static const Color cocoa = Color(0xFF7A4E3B);
  static const Color caramel = Color(0xFFB07B4F);
  static const Color latte = Color(0xFFD7B58E);
  static const Color foam = Color(0xFFF5E9D7);
  static const Color cream = Color(0xFFFBF6EE);
  static const Color crema = Color(0xFFEFE2CC);
  static const Color accent = Color(0xFFC8501E); // bitter orange
  static const Color success = Color(0xFF6B8E4E);
  static const Color danger = Color(0xFFB3382C);
}

ThemeData buildCoffeeTheme() {
  final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: CoffeeColors.mocha,
    brightness: Brightness.light,
    primary: CoffeeColors.espresso,
    onPrimary: CoffeeColors.cream,
    secondary: CoffeeColors.caramel,
    onSecondary: CoffeeColors.espresso,
    surface: CoffeeColors.cream,
    onSurface: CoffeeColors.espresso,
    error: CoffeeColors.danger,
  );

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: CoffeeColors.cream,
    appBarTheme: const AppBarTheme(
      backgroundColor: CoffeeColors.cream,
      foregroundColor: CoffeeColors.espresso,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: CoffeeColors.espresso,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: CoffeeColors.espresso.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: CoffeeColors.crema, width: 1),
      ),
    ),
    splashFactory: InkRipple.splashFactory,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: CoffeeColors.espresso,
        foregroundColor: CoffeeColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: CoffeeColors.crema),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: CoffeeColors.crema),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: CoffeeColors.caramel, width: 2),
      ),
      labelStyle: const TextStyle(color: CoffeeColors.cocoa),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: CoffeeColors.foam,
      side: BorderSide(color: CoffeeColors.crema),
      labelStyle: const TextStyle(
        color: CoffeeColors.darkRoast,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: CoffeeColors.crema,
      thickness: 1,
      space: 1,
    ),
    textTheme: base.textTheme.apply(
      bodyColor: CoffeeColors.espresso,
      displayColor: CoffeeColors.espresso,
    ),
  );
}
