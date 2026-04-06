import 'dart:ui';

import 'package:flutter/material.dart';

class FRInk {
  const FRInk._();

  // Warm light foundation
  static const Color paper = Color(0xFFF3F0EB);
  static const Color paperDeep = Color(0xFFE8E3DC);
  static const Color paperSoft = Color(0xFFFDFBF8);

  // Typography & neutral rhythm
  static const Color ink = Color(0xFF1D120E);
  static const Color inkSoft = Color(0xFF473A32);
  static const Color inkMute = Color(0xFF8A7D74);
  static const Color inkFaint = Color(0xFFB6ABA1);
  static const Color hairline = Color(0x1A1D120E);
  static const Color hairlineSoft = Color(0x0E1D120E);

  // Premium dark moments
  static const Color dark = Color(0xFF21120D);
  static const Color darkElevated = Color(0xFF2B1913);

  // Gold emphasis (selective)
  static const Color gold = Color(0xFFDEB47A);
  static const Color goldSoft = Color(0xFFEED7BA);

  // Existing accent compatibility
  static const Color saffron = Color(0xFFB67A3A);
  static const Color saffronDeep = Color(0xFF8D5925);
  static const Color saffronWash = Color(0x1AB67A3A);

  // Semantics
  static const Color rise = Color(0xFFB3371F);
  static const Color fall = Color(0xFF2E7A4B);
  static const Color riseWash = Color(0x14B3371F);
  static const Color fallWash = Color(0x142E7A4B);

  static const double gutter = 22.0;
  static const double rowV = 18.0;
  static const double sectionGap = 36.0;
}

class FRType {
  const FRType._();

  static const String family = 'Outfit';

  static const TextStyle display = TextStyle(
    fontFamily: family,
    fontSize: 42,
    height: 1.02,
    letterSpacing: -1.2,
    fontWeight: FontWeight.w800,
    color: FRInk.ink,
  );

  static const TextStyle title = TextStyle(
    fontFamily: family,
    fontSize: 28,
    height: 1.1,
    letterSpacing: -0.5,
    fontWeight: FontWeight.w800,
    color: FRInk.ink,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: family,
    fontSize: 18,
    height: 1.2,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w700,
    color: FRInk.ink,
  );

  static const TextStyle body = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: FRInk.inkSoft,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: family,
    fontSize: 15,
    height: 1.4,
    fontWeight: FontWeight.w700,
    color: FRInk.ink,
  );

  static const TextStyle micro = TextStyle(
    fontFamily: family,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w700,
    color: FRInk.inkMute,
  );

  static const TextStyle numeral = TextStyle(
    fontFamily: family,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
    color: FRInk.ink,
  );
}

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
