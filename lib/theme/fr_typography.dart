import 'package:flutter/material.dart';

import 'fr_colors.dart';

/// Canonical typography tokens for new UI code.
class FRTypography {
  const FRTypography._();

  static const String fontFamily = 'Outfit';
  static const String serifFamily = 'DMSerifDisplay';

  static const TextStyle titleLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: FRColors.textPrimary,
    height: 1.2,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: FRColors.textPrimary,
    height: 1.25,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: FRColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle bodySmMuted = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: FRColors.textMuted,
    height: 1.4,
  );

  static const TextStyle labelXs = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: FRColors.textMuted,
    letterSpacing: 0.4,
  );

  static const TextStyle serifDisplay = TextStyle(
    fontFamily: serifFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: FRColors.textPrimary,
    height: 1.2,
  );
}
