import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FiyatRadar premium grocery-tech tokens.
/// Dark warm: espresso base, gold / tan accent.
class FR {
  // Canvas stack
  static const bg = Color(0xFF120B07);
  static const bgElev = Color(0xFF1A120C);
  static const surface = Color(0xFF201611);
  static const surfaceHi = Color(0xFF2A1F18);
  static const surfaceLo = Color(0xFF16100B);

  // Borders / dividers
  static const hairline = Color(0xFF352820);
  static const hairlineSoft = Color(0xFF2A1F18);

  // Warm gold accent
  static const gold = Color(0xFFD7B27A);
  static const goldHi = Color(0xFFEACB96);
  static const goldDeep = Color(0xFFB48B52);
  static const copper = Color(0xFF8F5A34);

  // Text
  static const ink = Color(0xFFF3E9DC);
  static const ink2 = Color(0xFFCBB8A2);
  static const ink3 = Color(0xFF8E7E6E);
  static const ink4 = Color(0xFF5C4F44);

  // Semantic
  static const good = Color(0xFF78B388);
  static const goodSoft = Color(0xFF1E2A20);
  static const warn = Color(0xFFE1A24A);
  static const bad = Color(0xFFD9685E);
  static const badSoft = Color(0xFF2C1A17);
}

class FRRad {
  static const s = 10.0;
  static const m = 14.0;
  static const l = 18.0;
  static const xl = 22.0;
  static const xxl = 28.0;
  static const pill = 999.0;

  static BorderRadius all(double r) => BorderRadius.all(Radius.circular(r));
}

class FRSpace {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 20.0;
  static const xxl = 28.0;
}

List<BoxShadow> frShadow({double blur = 20, double y = 10, double opacity = .35}) =>
    [BoxShadow(color: Colors.black.withOpacity(opacity), blurRadius: blur, offset: Offset(0, y))];

List<BoxShadow> frGoldGlow({double opacity = .22}) =>
    [BoxShadow(color: FR.gold.withOpacity(opacity), blurRadius: 24, offset: const Offset(0, 10))];

TextStyle frDisplay(double size, FontWeight w,
        {Color color = FR.ink, double? height, double letter = -0.6}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color,
      letterSpacing: letter,
      height: height,
    );

TextStyle frSerifItalic(double size, FontWeight w, {Color color = FR.ink2}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color,
      fontStyle: FontStyle.italic,
      letterSpacing: -0.4,
    );

TextStyle frText(double size, FontWeight w,
        {Color color = FR.ink, double? letter, double? height}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: w,
      color: color,
      letterSpacing: letter,
      height: height,
    );

TextStyle frOverline({Color color = FR.goldDeep, double size = 10}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: FontWeight.w800,
      color: color,
      letterSpacing: 2.1,
    );

TextStyle frPrice(double size, {Color color = FR.ink, FontWeight w = FontWeight.w700}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: w,
      color: color,
      letterSpacing: -0.8,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

BoxDecoration frSurface({
  double radius = FRRad.xl,
  Color? color,
  Color? border,
}) =>
    BoxDecoration(
      color: color ?? FR.surface,
      borderRadius: FRRad.all(radius),
      border: Border.all(color: border ?? FR.hairline),
    );

BoxDecoration frElevated({double radius = FRRad.xl, Color? color}) => BoxDecoration(
      color: color ?? FR.surface,
      borderRadius: FRRad.all(radius),
      border: Border.all(color: FR.hairline),
      boxShadow: frShadow(),
    );
