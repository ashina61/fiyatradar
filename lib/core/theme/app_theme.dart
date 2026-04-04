import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppSpace {
  AppSpace._();
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AppRadius {
  AppRadius._();
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const pill = 999.0;
}

class AppElevation {
  AppElevation._();
  static const card = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.24),
      blurRadius: 14,
      offset: Offset(0, 8),
    )
  ];
}

class AppTheme {
  AppTheme._();

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bgPrimary,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.tan,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      secondary: AppColors.goldFog,
      error: AppColors.danger,
    ),
    textTheme: GoogleFonts.interTextTheme().copyWith(
      headlineLarge: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
      headlineMedium: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
      bodyLarge: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
      bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSubtle),
    ),
  );
}
