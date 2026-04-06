import 'package:flutter/material.dart';

import 'colors.dart';

class FRDsShadows {
  const FRDsShadows._();

  static const List<BoxShadow> shadowSoft = [
    BoxShadow(color: Color(0x0D2F2115), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const List<BoxShadow> shadowCard = [
    BoxShadow(color: Color(0x142F2115), blurRadius: 16, offset: Offset(0, 8)),
  ];
  static const List<BoxShadow> shadowFloating = [
    BoxShadow(color: Color(0x1F2F2115), blurRadius: 24, offset: Offset(0, 12)),
  ];
  static const List<BoxShadow> shadowDarkHero = [
    BoxShadow(color: FRDsColors.frSurfaceDark, blurRadius: 36, spreadRadius: -18),
  ];
}
