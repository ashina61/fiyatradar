// Executive design tokens — light-first palette.
// HTML ref: reference/designprototype (CSS :root variables).
// Parallel to legacy lib/widgets/prototype_ui.dart (ProtoColors); use these
// for all new executive-era UI.

import 'package:flutter/material.dart';

class ExecutiveColors {
  // Surfaces (warm light)
  static const bg = Color(0xFFEDEAE3);
  static const bgSoft = Color(0xFFF3F0E9);
  static const bgDeep = Color(0xFFE4DFD6);
  static const surface = Color(0xFFFFFFFF);
  static const surface2 = Color(0xFFFAF7F1);

  // Dark premium (espresso)
  static const espresso = Color(0xFF1A110A);
  static const espresso2 = Color(0xFF231710);
  static const espresso3 = Color(0xFF2E2016);

  // Gold accent (restrained)
  static const gold = Color(0xFFC9A063);
  static const goldSoft = Color(0xFFD8B783);
  static const goldDeep = Color(0xFFA57E46);
  static const goldWash = Color(0x1FC9A063); // rgba(201,160,99,.12)

  // Ink (text on light)
  static const ink = Color(0xFF1A110A);
  static const ink2 = Color(0xFF463527);
  static const ink3 = Color(0xFF7A6A5A);
  static const ink4 = Color(0xFFA79884);

  // Ink on dark
  static const inkOnDark = Color(0xFFF4EDE0);
  static const inkOnDark2 = Color(0xFFC9BCA6);
  static const inkOnDark3 = Color(0xFF7A6A56);

  // Semantic
  static const positive = Color(0xFF3E7D4F);
  static const positiveSoft = Color(0xFFE4F0DE);
  static const negative = Color(0xFFB4422F);
  static const negativeSoft = Color(0xFFF5E1DC);
  static const neutral = Color(0xFF6B5F50);

  // Subtle borders (on light + on dark)
  static const borderOnLight = Color(0x0F1A110A); // rgba(26,17,10,.06)
  static const borderOnDark = Color(0x2EC9A063);  // rgba(201,160,99,.18)
}

class FRRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
  static const double xxl = 34;
  static const double bezel = 44;
  static const double pill = 999;

  static const rSm = BorderRadius.all(Radius.circular(sm));
  static const rMd = BorderRadius.all(Radius.circular(md));
  static const rLg = BorderRadius.all(Radius.circular(lg));
  static const rXl = BorderRadius.all(Radius.circular(xl));
  static const rXxl = BorderRadius.all(Radius.circular(xxl));
  static const rPill = BorderRadius.all(Radius.circular(pill));
  static const rSheet = BorderRadius.only(
    topLeft: Radius.circular(30),
    topRight: Radius.circular(30),
  );
}

class FRSpacing {
  // Base rhythm derived from --pad: 20 and observed gaps.
  static const double x3 = 3;
  static const double x4 = 4;
  static const double x6 = 6;
  static const double x8 = 8;
  static const double x10 = 10;
  static const double x12 = 12;
  static const double x14 = 14;
  static const double x16 = 16;
  static const double x18 = 18;
  static const double x20 = 20; // --pad
  static const double x22 = 22;
  static const double x24 = 24;
  static const double x28 = 28;
  static const double x32 = 32;

  static const pageHPad = EdgeInsets.symmetric(horizontal: 20);
}

class FRShadows {
  // --shadow-sm
  static const List<BoxShadow> sm = [
    BoxShadow(offset: Offset(0, 1), blurRadius: 2, color: Color(0x0A1A110A)),
    BoxShadow(offset: Offset(0, 2), blurRadius: 6, color: Color(0x0A1A110A)),
  ];

  // --shadow-md
  static const List<BoxShadow> md = [
    BoxShadow(offset: Offset(0, 4), blurRadius: 14, color: Color(0x0F1A110A)),
    BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color(0x0F1A110A)),
  ];

  // --shadow-lg
  static const List<BoxShadow> lg = [
    BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color(0x141A110A)),
    BoxShadow(offset: Offset(0, 30), blurRadius: 60, color: Color(0x191A110A)),
  ];

  // --shadow-gold (drop). The CSS spec has a "0 0 0 1px" ring component;
  // in Flutter we treat that as a Border, not a BoxShadow. See FRDecor.goldRing.
  static const List<BoxShadow> gold = [
    BoxShadow(offset: Offset(0, 10), blurRadius: 30, color: Color(0x40C9A063)),
  ];
}

class FRGradients {
  // Gold CTA: linear-gradient(135deg, #C9A063 0%, #A57E46 100%)
  static const goldCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ExecutiveColors.gold, ExecutiveColors.goldDeep],
  );

  // Executive pill: linear-gradient(135deg, #2a1d11 0%, #1a110a 100%)
  static const pillExec = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A1D11), ExecutiveColors.espresso],
  );

  // FAB: linear-gradient(145deg, #2e2016 0%, #1a110a 100%)
  static const fab = LinearGradient(
    begin: Alignment(-0.5, -1),
    end: Alignment(0.5, 1),
    colors: [ExecutiveColors.espresso3, ExecutiveColors.espresso],
  );

  // Danger CTA (sheet)
  static const dangerCta = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFB4422F), Color(0xFF8A2F20)],
  );
}
