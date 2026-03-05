import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home_shell_screen.dart';

class FRColors {
  static const background = Color(0xFFF9F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF6B4226);
  static const dark = Color(0xFF2A1A10);
  static const gold = Color(0xFFC89B7B);
  static const muted = Color(0xFF9E8E82);
  static const danger = Color(0xFFA33333);
  static const warning = Color(0xFFB58461);
}

class FiyatRadarApp extends StatelessWidget {
  const FiyatRadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.outfitTextTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FiyatRadar',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: FRColors.background,
        textTheme: baseText,
        colorScheme: const ColorScheme.light(
          surface: FRColors.surface,
          primary: FRColors.primary,
          onPrimary: FRColors.surface,
          onSurface: FRColors.dark,
          error: FRColors.danger,
        ),
      ),
      home: const HomeShellScreen(),
    );
  }
}
