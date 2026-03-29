import 'package:flutter/widgets.dart';

/// Canonical radius tokens for new UI code.
class FRRadius {
  const FRRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double pill = 999;

  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius smPlusRadius = BorderRadius.all(Radius.circular(smPlus));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius mdPlusRadius = BorderRadius.all(Radius.circular(mdPlus));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxxlRadius = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));
}
