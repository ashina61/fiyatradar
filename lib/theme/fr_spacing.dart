import 'package:flutter/widgets.dart';

/// Canonical spacing tokens for new UI code.
class FRSpacing {
  const FRSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double xsPlus = 6;
  static const double sm = 8;
  static const double smPlus = 10;
  static const double md = 12;
  static const double mdPlus = 14;
  static const double lg = 16;
  static const double lgPlus = 18;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double xxxlPlus = 36;
  static const double heroHeaderBottom = 50;
  static const double footerBottomInset = 160;

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

  static const EdgeInsets allXxs = EdgeInsets.all(FRSpacing.xxs);
  static const EdgeInsets allSm = EdgeInsets.all(FRSpacing.sm);
  static const EdgeInsets allMd = EdgeInsets.all(FRSpacing.md);
  static const EdgeInsets allLg = EdgeInsets.all(FRSpacing.lg);
  static const EdgeInsets allSmPlus = EdgeInsets.all(FRSpacing.smPlus);
  static const EdgeInsets allLgPlus = EdgeInsets.all(FRSpacing.lgPlus);
  static const EdgeInsets allXl = EdgeInsets.all(FRSpacing.xl);
  static const EdgeInsets allXxl = EdgeInsets.all(FRSpacing.xxl);

  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: FRSpacing.lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: FRSpacing.xl);
  static const EdgeInsets verticalXxl = EdgeInsets.symmetric(vertical: FRSpacing.xxl);
  static const EdgeInsets verticalMdPlus = EdgeInsets.symmetric(vertical: FRSpacing.mdPlus);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: FRSpacing.md);
  static const EdgeInsets horizontalXxl = EdgeInsets.symmetric(horizontal: FRSpacing.xxl);
  static const EdgeInsets horizontalMdVerticalSm =
      EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.sm);
  static const EdgeInsets horizontalMdVerticalXs =
      EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.xs);

  static const EdgeInsets bottomSmPlus = EdgeInsets.only(bottom: FRSpacing.smPlus);
  static const EdgeInsets bottomMd = EdgeInsets.only(bottom: FRSpacing.md);
  static const EdgeInsets bottomLg = EdgeInsets.only(bottom: FRSpacing.lg);
  static const EdgeInsets bottomXl = EdgeInsets.only(bottom: FRSpacing.xl);
  static const EdgeInsets rightLg = EdgeInsets.only(right: FRSpacing.lg);
  static const EdgeInsets leftSmPlus = EdgeInsets.only(left: FRSpacing.smPlus);
  static const EdgeInsets topXxxlPlus = EdgeInsets.only(top: FRSpacing.xxxlPlus);

  static const EdgeInsets pointsChip =
      EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.xsPlus);
  static const EdgeInsets searchBar =
      EdgeInsets.fromLTRB(FRSpacing.lg, FRSpacing.xsPlus, FRSpacing.xsPlus, FRSpacing.xsPlus);
  static const EdgeInsets categoryPill =
      EdgeInsets.symmetric(horizontal: FRSpacing.mdPlus, vertical: FRSpacing.smPlus);
  static const EdgeInsets insightSection =
      EdgeInsets.fromLTRB(FRSpacing.xxl, FRSpacing.xl, FRSpacing.xxl, 0);
  static const EdgeInsets insightCard =
      EdgeInsets.fromLTRB(FRSpacing.lg, FRSpacing.lg, FRSpacing.lg, FRSpacing.mdPlus);
  static const EdgeInsets sectionTop =
      EdgeInsets.fromLTRB(FRSpacing.xxl, FRSpacing.xxl, FRSpacing.xxl, 0);
  static const EdgeInsets sectionXxlTop =
      EdgeInsets.fromLTRB(FRSpacing.xxl, FRSpacing.xxxl, FRSpacing.xxl, 0);
  static const EdgeInsets ctaChip =
      EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: 9);
  static const EdgeInsets latestListContainer =
      EdgeInsets.symmetric(horizontal: FRSpacing.xl, vertical: FRSpacing.sm);
  static const EdgeInsets trendBadge =
      EdgeInsets.symmetric(horizontal: FRSpacing.sm, vertical: 5);
  static const EdgeInsets popularBadge =
      EdgeInsets.symmetric(horizontal: FRSpacing.sm, vertical: FRSpacing.xs);
  static const EdgeInsets footer = EdgeInsets.fromLTRB(
    FRSpacing.xxl,
    FRSpacing.sm,
    FRSpacing.xxl,
    FRSpacing.footerBottomInset,
  );

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

  static EdgeInsets headerWithTop(double top, {double bottom = FRSpacing.heroHeaderBottom}) =>
      EdgeInsets.fromLTRB(FRSpacing.xxl, top + FRSpacing.lg, FRSpacing.xxl, bottom);


  static EdgeInsets all(double value) => EdgeInsets.all(value);

  static EdgeInsets only({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) =>
      EdgeInsets.only(left: left, top: top, right: right, bottom: bottom);

  static EdgeInsets fromLTRB(double left, double top, double right, double bottom) =>
      EdgeInsets.fromLTRB(left, top, right, bottom);

  static EdgeInsets symmetric({
    double horizontal = 0,
    double vertical = 0,
  }) =>
      EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
}
