import 'package:flutter/widgets.dart';

/// Canonical radius tokens for new UI code.
class FRRadius {
  const FRRadius._();

  static const double xxs = 5;
  static const double xs = 6;
  static const double xsPlus = 7;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdTight = 13;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double lgPlus = 18;
  static const double xl = 20;
  static const double xxlTight = 22;
  static const double xxl = 24;
  static const double xxxl = 28;
  static const double hero = 32;
  static const double heroXl = 36;
  static const double pill = 999;

  static const BorderRadius xxsRadius = BorderRadius.all(Radius.circular(xxs));
  static const BorderRadius xsRadius = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius xsPlusRadius = BorderRadius.all(Radius.circular(xsPlus));
  static const BorderRadius smRadius = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius smPlusRadius = BorderRadius.all(Radius.circular(smPlus));
  static const BorderRadius mdRadius = BorderRadius.all(Radius.circular(md));
  static const BorderRadius mdTightRadius = BorderRadius.all(Radius.circular(mdTight));
  static const BorderRadius mdPlusRadius = BorderRadius.all(Radius.circular(mdPlus));
  static const BorderRadius lgRadius = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius lgPlusRadius = BorderRadius.all(Radius.circular(lgPlus));
  static const BorderRadius xlRadius = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius xxlTightRadius = BorderRadius.all(Radius.circular(xxlTight));
  static const BorderRadius xxlRadius = BorderRadius.all(Radius.circular(xxl));
  static const BorderRadius xxxlRadius = BorderRadius.all(Radius.circular(xxxl));
  static const BorderRadius heroRadius = BorderRadius.all(Radius.circular(hero));
  static const BorderRadius pillRadius = BorderRadius.all(Radius.circular(pill));

  static BorderRadius all(double radius) => BorderRadius.all(Radius.circular(radius));
}
