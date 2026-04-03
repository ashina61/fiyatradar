import 'package:flutter/material.dart';

import '../theme/fr_foundation.dart';

class FRSectionHeader extends StatelessWidget {
  const FRSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.titleColor = FRColors.textPrimaryDark,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: FRColors.tan),
          const SizedBox(width: FRSpacing.sm),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ).copyWith(color: titleColor),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
