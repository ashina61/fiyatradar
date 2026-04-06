import 'package:flutter/material.dart';

import 'colors.dart';

class FRDsTypography {
  const FRDsTypography._();

  static const String _family = 'Outfit';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    height: 1.15,
    fontWeight: FontWeight.w800,
    color: FRDsColors.frTextPrimary,
  );
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: FRDsColors.frTextPrimary,
  );
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: FRDsColors.frTextPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: FRDsColors.frTextPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: FRDsColors.frTextSecondary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w500,
    color: FRDsColors.frTextSecondary,
  );
  static const TextStyle labelCapsule = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: FRDsColors.frTextPrimary,
  );
  static const TextStyle sectionEyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 11,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w700,
    color: FRDsColors.frTextMuted,
  );
}
