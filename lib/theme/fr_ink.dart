// lib/theme/fr_ink.dart
// GREENFIELD v2 — "Quiet Intelligence" design tokens.
// Rejected: FRColors.backgroundWarm + brown card chrome + soft shadows + rounded FAB.
// This file introduces a new visual language: ink-on-ivory, single accent,
// hairline dividers, generous rhythm, display typography.

import 'package:flutter/material.dart';

class FRInk {
  const FRInk._();

  // ── Paper & ink ────────────────────────────────────────────────────────────
  static const Color paper       = Color(0xFFF6F2EA); // main background
  static const Color paperDeep   = Color(0xFFEDE7DB); // secondary surfaces
  static const Color paperSoft   = Color(0xFFFBF8F2); // elevated fields
  static const Color ink         = Color(0xFF0E0E0C); // primary text
  static const Color inkSoft     = Color(0xFF3A372F); // body
  static const Color inkMute     = Color(0xFF8B857A); // muted labels
  static const Color inkFaint    = Color(0xFFB8B1A3); // hints
  static const Color hairline    = Color(0x1A0E0E0C); // dividers
  static const Color hairlineSoft= Color(0x0E0E0E0C);

  // ── Accent (single) ────────────────────────────────────────────────────────
  static const Color saffron     = Color(0xFFD97A2C);
  static const Color saffronDeep = Color(0xFFB35F17);
  static const Color saffronWash = Color(0x1AD97A2C);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color rise        = Color(0xFFB3371F); // price up = bad
  static const Color fall        = Color(0xFF2E7A4B); // price down = good
  static const Color riseWash    = Color(0x14B3371F);
  static const Color fallWash    = Color(0x142E7A4B);

  // ── Rhythm ─────────────────────────────────────────────────────────────────
  static const double gutter     = 22.0;
  static const double rowV       = 18.0;
  static const double sectionGap = 36.0;
}

/// Type scale — deliberately editorial, no Material presets.
class FRType {
  const FRType._();

  static const String family = 'Outfit';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 44,
    height: 1.02,
    letterSpacing: -1.4,
    fontWeight: FontWeight.w700,
    color: FRInk.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 26,
    height: 1.1,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
    color: FRInk.ink,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 1.2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w600,
    color: FRInk.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.42,
    letterSpacing: 0,
    fontWeight: FontWeight.w400,
    color: FRInk.inkSoft,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.42,
    fontWeight: FontWeight.w600,
    color: FRInk.ink,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
    color: FRInk.inkMute,
  );

  static const TextStyle numeral = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: FRInk.ink,
  );
}

/// A thin full-width hairline divider used as the primary separator.
class FRHairline extends StatelessWidget {
  const FRHairline({super.key, this.indent = 0});
  final double indent;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.only(left: indent),
      color: FRInk.hairline,
    );
  }
}
