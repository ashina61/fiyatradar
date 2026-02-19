import 'package:flutter/animation.dart';

class MotionTokens {
  const MotionTokens._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration navigation = Duration(milliseconds: 280);

  static const Curve standard = Curves.easeOutCubic;
}
