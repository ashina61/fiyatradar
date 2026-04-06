import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRSelectionCard extends StatelessWidget {
  const FRSelectionCard({required this.child, super.key, this.selected = false, this.onTap});

  final Widget child;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: FRDsRadius.lg,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? FRDsColors.frGoldSoft : FRDsColors.frSurface,
          borderRadius: FRDsRadius.lg,
          border: Border.all(color: selected ? FRDsColors.frGold : FRDsColors.frBorderSoft),
        ),
        child: child,
      ),
    );
  }
}
