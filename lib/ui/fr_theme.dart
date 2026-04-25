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
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _FRPageTransitionsBuilder(),
        TargetPlatform.iOS: _FRPageTransitionsBuilder(),
        TargetPlatform.macOS: _FRPageTransitionsBuilder(),
        TargetPlatform.windows: _FRPageTransitionsBuilder(),
        TargetPlatform.linux: _FRPageTransitionsBuilder(),
        TargetPlatform.fuchsia: _FRPageTransitionsBuilder(),
      },
    ),
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
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.bg,
      surfaceTintColor: palette.bg,
      modalBackgroundColor: palette.bg,
      modalBarrierColor: palette.ink.withOpacity(isDark ? .5 : .22),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: palette.surface,
      shape: RoundedRectangleBorder(borderRadius: FRRad.all(FRRad.m)),
      textStyle: frText(13, FontWeight.w600, color: palette.ink),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: palette.gold,
      selectionColor: palette.gold.withOpacity(.3),
      selectionHandleColor: palette.gold,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? palette.gold : palette.ink3,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? palette.gold.withOpacity(.5)
            : palette.hairline,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.gold,
        textStyle: frText(12.5, FontWeight.w800, color: palette.gold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.ink2,
        side: BorderSide(color: palette.hairline),
        textStyle: frText(12.5, FontWeight.w700, color: palette.ink2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.gold,
        foregroundColor: palette.bg,
        textStyle: frText(12.5, FontWeight.w800, color: palette.bg),
      ),
    ),
    dividerColor: palette.hairline,
    iconTheme: IconThemeData(color: palette.ink2),
  );
}

/// Subtle fade-through + tiny lift. Cheap on both iOS and Android and feels
/// intentional instead of the default slide.
class _FRPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FRPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
