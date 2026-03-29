import 'package:flutter/widgets.dart';

/// Canonical spacing tokens for new UI code.
class FRSpacing {
  const FRSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double lgPlus = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: xxl, vertical: lg);
  static const EdgeInsets card = EdgeInsets.all(lg);
  static const EdgeInsets chip = EdgeInsets.symmetric(horizontal: md, vertical: xs);
  static const EdgeInsets button = EdgeInsets.symmetric(horizontal: xxl, vertical: md);
}

/// EdgeInsets helpers backed by canonical spacing tokens.
class FRSpaceInsets {
  const FRSpaceInsets._();

  static const EdgeInsets page = FRSpacing.page;
  static const EdgeInsets card = FRSpacing.card;
  static const EdgeInsets chip = FRSpacing.chip;
  static const EdgeInsets button = FRSpacing.button;

  static const EdgeInsets allSm = EdgeInsets.all(FRSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(FRSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(FRSpacing.lg);
  static const EdgeInsets allSmPlus = EdgeInsets.all(FRSpacing.smPlus);
  static const EdgeInsets allLgPlus = EdgeInsets.all(FRSpacing.lgPlus);
  static const EdgeInsets allXl = EdgeInsets.all(FRSpacing.xl);
  static const EdgeInsets allXxl = EdgeInsets.all(FRSpacing.xxl);

  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: FRSpacing.xl);
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: FRSpacing.xxl);
  static const EdgeInsets verticalMdPlus = EdgeInsets.symmetric(vertical: FRSpacing.mdPlus);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: FRSpacing.md);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: FRSpacing.xxl);
  static const EdgeInsets horizontalMdVerticalXs =
      EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.xs);

  static const EdgeInsets bottomSmPlus = EdgeInsets.only(bottom: FRSpacing.smPlus);
  static const EdgeInsets bottomLg = EdgeInsets.only(bottom: FRSpacing.lg);
  static const EdgeInsets rightLg = EdgeInsets.only(right: FRSpacing.lg);

  static const EdgeInsets screenBody = EdgeInsets.fromLTRB(
    FRSpacing.lg,
    FRSpacing.lg,
    FRSpacing.lg,
    0,
  );

  static const EdgeInsets header = EdgeInsets.fromLTRB(
    FRSpacing.xl,
    FRSpacing.xxl,
    FRSpacing.xl,
    FRSpacing.xl,
  );

  static const EdgeInsets productCard = EdgeInsets.fromLTRB(
    FRSpacing.md,
    FRSpacing.mdPlus,
    FRSpacing.md,
    FRSpacing.smPlus,
  );

  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
