import 'package:flutter/material.dart';

import 'fr_colors.dart';

/// Canonical shadow/elevation tokens for new UI code.
class FRElevation {
  const FRElevation._();

  static const List<BoxShadow> soft = [
    BoxShadow(color: FRColors.shadowSoft, blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: FRColors.shadowMedium, blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> strong = [
    BoxShadow(color: FRColors.shadowStrong, blurRadius: 22, offset: Offset(0, 8)),
  ];

  static const List<BoxShadow> refCard = [
    BoxShadow(color: Color(0x2E000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
}
