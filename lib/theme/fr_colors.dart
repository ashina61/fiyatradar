import 'package:flutter/material.dart';

/// Canonical color source for the FiyatRadar design foundation.
///
/// Rules:
/// - New UI code must consume semantic colors from this class.
/// - Do not introduce parallel palette classes for new features.
/// - Legacy palette classes can stay temporarily, but are deprecated.
class FRColors {
  const FRColors._();

  static const Color espresso = Color(0xFF18100A);
  static const Color espressoSoft = Color(0xFF2C2418);
  static const Color tan = Color(0xFFBF9470);
  static const Color tanLight = Color(0xFFD4B599);
  static const Color camel = Color(0xFFC09A60);
  static const Color camelStrong = Color(0xFFC29B78);
  static const Color camelDeep = Color(0xFFA67C52);
  static const Color studio = Color(0xFFEBE5DF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFAFAFA);
  static const Color surfaceAlt = surfaceSoft;
  static const Color background = Color(0xFFF5F3F0);
  static const Color backgroundWarm = Color(0xFFEFECE6);
  static const Color bgApp = backgroundWarm;
  static const Color textPrimary = espressoSoft;
  static const Color textMuted = Color(0xFF8E847A);
  static const Color textMutedSoft = Color(0xFF948A82);
  static const Color textHint = Color(0xFFB3ABA3);
  static const Color textSubtle = Color(0xFFAFA59D);
  static const Color border = Color(0x0D211510);
  static const Color borderLight = border;
  static const Color borderStrong = Color(0x33C29B78);
  static const Color shadowSoft = Color(0x0A211510);
  static const Color shadowMedium = Color(0x14211510);
  static const Color shadowStrong = Color(0x33170D08);
  static const Color white = Color(0xFFFFFFFF);
  static const Color whiteMuted = Color(0x99FFFFFF);
  static const Color success = Color(0xFF27A85A);
  static const Color successSurface = Color(0xFFE8F5E9);
  static const Color danger = Color(0xFFE53935);
  static const Color dangerSurface = Color(0xFFFFEBEE);
  static const Color mapBlue = Color(0xFF1E40AF);
  static const Color sapphire = Color(0xFF1976D2);
  static const Color sapphireSurface = Color(0x261976D2);
  static const Color silver = Color(0xFFB0BEC5);
  static const Color silverDeep = Color(0xFF78909C);
  static const Color ivory = Color(0xFFFFE6C9);
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldGlow = gold;
  static const Color goldGlowSoft = Color(0xFFF4D06F);

  static Color camelOverlay(double opacity) => camelStrong.withOpacity(opacity);
  static Color successBg(double opacity) => success.withOpacity(opacity);
  static Color dangerBg(double opacity) => danger.withOpacity(opacity);
  static Color goldBg(double opacity) => gold.withOpacity(opacity);
  static Color espressoOverlay(double opacity) => espresso.withOpacity(opacity);
}
