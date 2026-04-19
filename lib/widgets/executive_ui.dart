import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Prototype token map (reference/designprototype CSS vars).
class ExecColors {
  static const bg = Color(0xFFEDEAE3);
  static const bgSoft = Color(0xFFF3F0E9);
  static const bgDeep = Color(0xFFE4DFD6);
  static const surface = Colors.white;
  static const surface2 = Color(0xFFFAF7F1);

  static const espresso = Color(0xFF1A110A);
  static const espresso2 = Color(0xFF231710);
  static const espresso3 = Color(0xFF2E2016);

  static const gold = Color(0xFFC9A063);
  static const goldSoft = Color(0xFFD8B783);
  static const goldDeep = Color(0xFFA57E46);

  static const ink = Color(0xFF1A110A);
  static const ink2 = Color(0xFF463527);
  static const ink3 = Color(0xFF7A6A5A);
  static const ink4 = Color(0xFFA79884);
  static const onDark = Color(0xFFF4EDE0);

  static const success = Color(0xFF3E7D4F);
  static const successSoft = Color(0xFFE4F0DE);
  static const danger = Color(0xFFB4422F);
  static const dangerSoft = Color(0xFFF5E1DC);
}

class ExecRadii {
  static final sm = BorderRadius.circular(10);
  static final md = BorderRadius.circular(16);
  static final lg = BorderRadius.circular(22);
  static final xl = BorderRadius.circular(28);
  static final xxl = BorderRadius.circular(34);
  static final pill = BorderRadius.circular(999);
}

TextStyle fraunces(
  double size,
  FontWeight weight, {
  Color color = ExecColors.ink,
  FontStyle? style,
  double? height,
}) =>
    GoogleFonts.fraunces(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: -0.3,
      fontStyle: style,
      height: height,
    );

TextStyle manrope(
  double size,
  FontWeight weight, {
  Color color = ExecColors.ink,
  double? height,
  double? letterSpacing,
}) =>
    GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );

BoxDecoration execCard({double radius = 22}) => BoxDecoration(
      color: ExecColors.surface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: ExecColors.bgDeep),
      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 14, offset: Offset(0, 4))],
    );
