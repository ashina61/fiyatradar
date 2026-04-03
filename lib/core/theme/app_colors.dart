import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bgPrimary = Color(0xFF1A1614);
  static const Color bgSecondary = Color(0xFF24201D);
  static const Color surface = Color(0xFF2A2522);
  static const Color surfaceAlt = Color(0xFF312C29);
  static const Color border = Color.fromRGBO(61, 54, 51, 0.4);
  static const Color textPrimary = Color.fromRGBO(250, 246, 242, 0.96);
  static const Color textSecondary = Color.fromRGBO(210, 200, 190, 0.68);
  static const Color textSubtle = Color.fromRGBO(201, 191, 184, 0.42);
  static const Color tan = Color(0xFFC4A57B);
  static const Color success = Color(0xFF8A9A8B);
  static const Color successBg = Color.fromRGBO(138, 154, 139, 0.1);
  static const Color warning = Color(0xFFB58B7A);
  static const Color danger = Color(0xFFA67B7B);

  static const double radiusMd = 10;
  static const double radiusLg = 14;
  static const double radiusXl = 18;
  static const double radiusFull = 9999;

  static const BoxShadow shadowMd = BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.18),
    blurRadius: 6,
    offset: Offset(0, 2),
  );
}
