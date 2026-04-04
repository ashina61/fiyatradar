import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bgPrimary = Color(0xFF1E1411);
  static const Color bgSecondary = Color(0xFF2A1D18);
  static const Color surface = Color(0xFF34261F);
  static const Color surfaceAlt = Color(0xFF3E2E25);
  static const Color border = Color(0xFF5A463A);

  static const Color textPrimary = Color(0xFFF8EFE5);
  static const Color textSecondary = Color(0xFFD3C2B2);
  static const Color textSubtle = Color(0xFFA89280);

  static const Color tan = Color(0xFFCB9A67);
  static const Color goldFog = Color(0xFFE6C89E);
  static const Color success = Color(0xFF8FB189);
  static const Color warning = Color(0xFFD2A374);
  static const Color danger = Color(0xFFBE7B6A);

  static const double radiusMd = 12;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static const LinearGradient gradientMain = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF261914), Color(0xFF1A1310)],
  );
}
