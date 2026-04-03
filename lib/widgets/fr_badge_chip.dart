import 'package:flutter/material.dart';

import '../theme/fr_foundation.dart';

class FRBadgeChip extends StatelessWidget {
  const FRBadgeChip({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor = FRColors.surfaceAlt,
    this.foregroundColor = FRColors.textSecondary,
    this.borderColor = FRColors.border,
    this.padding = const EdgeInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.xsPlus),
  });

  final String label;
  final IconData? icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: FRRadius.pillRadius,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foregroundColor),
            const SizedBox(width: FRSpacing.xsPlus),
          ],
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: foregroundColor),
          ),
        ],
      ),
    );
  }
}
