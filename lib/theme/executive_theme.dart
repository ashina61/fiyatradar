// Executive ThemeData (Material 3, light). Wires tokens + FRType into the
// standard Theme so MaterialApp-aware widgets (AppBar, Input, etc.) inherit
// the executive look by default.
// Parallel to legacy buildCoffeeTheme in lib/theme.dart — do not delete that
// one until all screens are migrated.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';
import 'typography.dart';

ThemeData buildExecutiveTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: ExecutiveColors.espresso,
    brightness: Brightness.light,
    primary: ExecutiveColors.espresso,
    onPrimary: ExecutiveColors.inkOnDark,
    secondary: ExecutiveColors.gold,
    onSecondary: ExecutiveColors.espresso,
    surface: ExecutiveColors.surface,
    onSurface: ExecutiveColors.ink,
    error: ExecutiveColors.negative,
  );

  final baseTextTheme = GoogleFonts.manropeTextTheme();

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: ExecutiveColors.bg,
    canvasColor: ExecutiveColors.bg,
    splashColor: ExecutiveColors.goldWash,
    highlightColor: ExecutiveColors.goldWash,
    textTheme: baseTextTheme
        .apply(bodyColor: ExecutiveColors.ink2, displayColor: ExecutiveColors.ink)
        .copyWith(
          displayLarge: FRType.display(),
          headlineLarge: FRType.h1(),
          headlineMedium: FRType.h2(),
          headlineSmall: FRType.h3(),
          titleLarge: FRType.h4(),
          bodyLarge: FRType.body(size: 15),
          bodyMedium: FRType.body(),
          bodySmall: FRType.caption(),
          labelLarge: FRType.button(),
          labelMedium: FRType.overline(),
        ),
    appBarTheme: AppBarTheme(
      backgroundColor: ExecutiveColors.bg,
      foregroundColor: ExecutiveColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: FRType.h4(),
    ),
    iconTheme: const IconThemeData(color: ExecutiveColors.ink2, size: 22),
    dividerTheme: const DividerThemeData(
      color: ExecutiveColors.borderOnLight,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ExecutiveColors.surface,
      hintStyle: FRType.body(color: ExecutiveColors.ink4),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: FRRadius.rMd,
        borderSide: BorderSide(color: ExecutiveColors.borderOnLight),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: FRRadius.rMd,
        borderSide: BorderSide(color: ExecutiveColors.borderOnLight),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: FRRadius.rMd,
        borderSide: BorderSide(color: ExecutiveColors.gold, width: 1.5),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: ExecutiveColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: FRRadius.rSheet),
      modalBackgroundColor: ExecutiveColors.surface,
    ),
  );
}
