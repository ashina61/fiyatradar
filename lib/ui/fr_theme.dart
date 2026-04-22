import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

ThemeData buildFRTheme({required FRPalette palette}) {
  final isDark = palette.brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: palette.brightness,
    primary: palette.gold,
    onPrimary: palette.bg,
    secondary: palette.goldDeep,
    onSecondary: palette.ink,
    surface: palette.surface,
    onSurface: palette.ink,
    error: palette.bad,
    onError: palette.bg,
  );

  final baseText = (isDark ? ThemeData.dark() : ThemeData.light())
      .textTheme
      .apply(bodyColor: palette.ink, displayColor: palette.ink);
  final textTheme = GoogleFonts.manropeTextTheme(baseText);

  return ThemeData(
    useMaterial3: true,
    brightness: palette.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.bg,
    textTheme: textTheme,
    splashFactory: InkRipple.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      foregroundColor: palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      hintStyle: frText(13, FontWeight.w600, color: palette.ink3),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: BorderSide(color: palette.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: BorderSide(color: palette.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: BorderSide(color: palette.gold, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: FRRad.all(FRRad.m),
        borderSide: BorderSide(color: palette.bad),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceHi,
      contentTextStyle: frText(13, FontWeight.w700, color: palette.ink),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: FRRad.all(FRRad.m)),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: FRRad.all(FRRad.l)),
      titleTextStyle: frDisplay(22, FontWeight.w700, color: palette.ink),
      contentTextStyle:
          frText(13.5, FontWeight.w500, color: palette.ink2, height: 1.45),
    ),
    dividerColor: palette.hairline,
    iconTheme: IconThemeData(color: palette.ink2),
  );
}
