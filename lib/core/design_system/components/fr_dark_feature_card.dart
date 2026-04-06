import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRDarkFeatureCard extends StatelessWidget {
  const FRDarkFeatureCard({required this.child, super.key, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(color: FRDsColors.frSurfaceDarkElevated, borderRadius: FRDsRadius.lg),
      child: child,
    );
  }
}
