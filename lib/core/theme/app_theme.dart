import 'package:flutter/material.dart';

class AppColors {
  // Arka Plan & Yüzey Renkleri
  static const Color bgPrimary = Color(0xFF1A1614);
  static const Color bgSecondary = Color(0xFF24201D);
  static const Color surface = Color(0xFF2A2522);
  static const Color surfaceAlt = Color(0xFF312C29);
  static const Color border = Color(0x663D3633); // rgba(61, 54, 51, 0.4)
  
  // Metin Renkleri
  static const Color textPrimary = Color(0xF5FAF6F2); // rgba(250, 246, 242, 0.96)
  static const Color textSecondary = Color(0xADD2C8BE); // rgba(210, 200, 190, 0.68)
  static const Color textSubtle = Color(0x6BC9BFB8); // rgba(201, 191, 184, 0.42)
  
  // Vurgu ve Durum Renkleri
  static const Color tan = Color(0xFFC4A57B);
  static const Color success = Color(0xFF8A9A8B);
  static const Color successBg = Color(0x1A8A9A8B);
  static const Color warning = Color(0xFFB58B7A);
  static const Color danger = Color(0xFFA67B7B);
}

class AppRadii {
  static const BorderRadius md = BorderRadius.all(Radius.circular(10));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(14));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(18));
  static const BorderRadius full = BorderRadius.all(Radius.circular(9999));
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.tan,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      fontFamily: 'Inter', // Google Fonts paketini pubspec.yaml'a eklemeyi unutma
      
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          fontFamily: 'Inter',
        ),
      ),
      
      colorScheme: const ColorScheme.dark(
        primary: AppColors.tan,
        secondary: AppColors.tan,
        surface: AppColors.surface,
        background: AppColors.bgPrimary,
        error: AppColors.danger,
      ),
      
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
        displayMedium: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        bodySmall: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      
      // Buton Teması (Codex'e uygun)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tan,
          foregroundColor: AppColors.bgPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: AppRadii.lg,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}
