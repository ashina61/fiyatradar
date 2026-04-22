import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

ThemeData buildFRTheme() {
  const scheme = ColorScheme.dark(
    primary: FR.gold,
    onPrimary: FR.bg,
    secondary: FR.goldDeep,
    onSecondary: FR.ink,
    surface: FR.surface,
    onSurface: FR.ink,
    error: FR.bad,
  );

  final textTheme = GoogleFonts.manropeTextTheme(
    ThemeData.dark().textTheme.apply(bodyColor: FR.ink, displayColor: FR.ink),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: FR.bg,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: FR.bg,
      foregroundColor: FR.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: FR.surface,
      hintStyle: frText(13, FontWeight.w600, color: FR.ink3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: const BorderSide(color: FR.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: const BorderSide(color: FR.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: const BorderSide(color: FR.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: const BorderSide(color: FR.bad),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: FR.surfaceHi,
      contentTextStyle: frText(13, FontWeight.w700, color: FR.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: FRRad.all(FRRad.m)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: FR.surface,
      shape: RoundedRectangleBorder(borderRadius: FRRad.all(FRRad.l)),
      titleTextStyle: frDisplay(22, FontWeight.w700),
      contentTextStyle: frText(13.5, FontWeight.w500, color: FR.ink2, height: 1.45),
    ),
    dividerColor: FR.hairline,
  );
}
