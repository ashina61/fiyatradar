import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/shadows.dart';

class FRSurfaceCard extends StatelessWidget {
  const FRSurfaceCard({required this.child, super.key, this.padding = const EdgeInsets.all(16)});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: const BoxDecoration(
        color: FRDsColors.frSurface,
        borderRadius: FRDsRadius.lg,
        boxShadow: FRDsShadows.shadowCard,
      ),
      child: child,
    );
  }
}
