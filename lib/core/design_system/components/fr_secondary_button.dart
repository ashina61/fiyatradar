import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRSecondaryButton extends StatelessWidget {
  const FRSecondaryButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: FRDsColors.frBrownDeep),
      child: Text(label),
    );
  }
}
