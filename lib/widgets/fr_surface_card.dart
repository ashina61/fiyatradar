import 'package:flutter/material.dart';

import '../theme/fr_foundation.dart';

class FRSurfaceCard extends StatelessWidget {
  const FRSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(FRSpacing.lg),
    this.margin,
    this.radius = FRRadius.lg,
    this.color = FRColors.surface,
    this.borderColor = FRColors.border,
    this.shadow = FRElevation.soft,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color color;
  final Color borderColor;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: FRRadius.all(radius),
        border: Border.all(color: borderColor),
        boxShadow: shadow,
      ),
      child: child,
    );

    if (margin == null) return content;
    return Container(margin: margin, child: content);
  }
}
