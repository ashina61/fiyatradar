import 'package:flutter/material.dart';

import '../theme/fr_foundation.dart';

class FRButton extends StatelessWidget {
  const FRButton.primary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.expanded = false,
    this.height = 48,
  })  : variant = _FRButtonVariant.primary,
        foregroundColor = FRColors.bgPrimary,
        backgroundColor = FRColors.tan,
        borderColor = null;

  const FRButton.secondary({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.expanded = false,
    this.height = 48,
  })  : variant = _FRButtonVariant.secondary,
        foregroundColor = FRColors.textPrimaryDark,
        backgroundColor = FRColors.surfaceDark,
        borderColor = FRColors.borderDark;

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool expanded;
  final double height;
  final _FRButtonVariant variant;
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final style = ElevatedButton.styleFrom(
      minimumSize: Size(0, height),
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
      disabledForegroundColor: foregroundColor.withOpacity(0.6),
      disabledBackgroundColor: backgroundColor.withOpacity(0.6),
      shape: RoundedRectangleBorder(borderRadius: FRRadius.mdRadius),
      side: borderColor == null ? null : BorderSide(color: borderColor!),
      elevation: variant == _FRButtonVariant.primary ? 0 : 0,
      padding: FRSpaceInsets.symmetric(horizontal: FRSpacing.md, vertical: FRSpacing.sm),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    );

    final button = icon == null
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : ElevatedButton.icon(
            onPressed: onPressed,
            style: style,
            icon: Icon(icon, size: 16),
            label: Text(label),
          );

    if (!expanded) return button;
    return SizedBox(width: double.infinity, child: button);
  }
}

enum _FRButtonVariant { primary, secondary }
