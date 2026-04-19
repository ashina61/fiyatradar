// Typography roles — Fraunces (display serif) + Manrope (body sans).
// HTML ref: reference/designprototype (:root font-family rules + h1..h4).
// Letter-spacing converted from em to logical px at the declared size.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'tokens.dart';

class FRType {
  // ── Fraunces display / headings ──────────────────────────────────────────
  static TextStyle display({
    double size = 52,
    double height = 1.02,
    Color color = ExecutiveColors.ink,
  }) {
    return GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: height,
      letterSpacing: size * -0.02,
      color: color,
    );
  }

  static TextStyle h1({Color color = ExecutiveColors.ink}) => GoogleFonts.fraunces(
        fontSize: 44,
        fontWeight: FontWeight.w700,
        height: 1.0,
        letterSpacing: 44 * -0.03,
        color: color,
      );

  static TextStyle h2({Color color = ExecutiveColors.ink}) => GoogleFonts.fraunces(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.05,
        letterSpacing: 30 * -0.02,
        color: color,
      );

  static TextStyle h3({Color color = ExecutiveColors.ink}) => GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.15,
        letterSpacing: 22 * -0.01,
        color: color,
      );

  /// Italic accent used inside h2/h3 (e.g., "Trend <em>ürünler</em>").
  /// Apply via Text.rich with a TextSpan using this style for the em slice.
  static TextStyle emAccent({double size = 22, Color color = ExecutiveColors.ink3}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: FontWeight.w400,
        fontStyle: FontStyle.italic,
        height: 1.15,
        color: color,
      );

  /// Numeric Fraunces (prices). Tabular features enabled for stable columns.
  static TextStyle numeric({
    double size = 22,
    FontWeight weight = FontWeight.w700,
    Color color = ExecutiveColors.ink,
  }) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: size * -0.02,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  // ── Manrope body / utility ───────────────────────────────────────────────
  static TextStyle h4({Color color = ExecutiveColors.ink}) => GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 16 * -0.005,
        color: color,
      );

  static TextStyle body({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = ExecutiveColors.ink2,
    double height = 1.55,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color,
      );

  static TextStyle caption({Color color = ExecutiveColors.ink3}) =>
      GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: color,
      );

  /// Overline: uppercase premium label. Apply Text(text.toUpperCase()).
  static TextStyle overline({
    Color color = ExecutiveColors.ink3,
    double size = 11,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: size * 0.22,
        color: color,
      );

  static TextStyle button({Color color = ExecutiveColors.ink}) =>
      GoogleFonts.manrope(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 15 * 0.02,
        color: color,
      );
}
