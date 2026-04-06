import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRPrimaryButton extends StatelessWidget {
  const FRPrimaryButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: FRDsColors.frBrownDeep),
      child: Text(label),
    );
  }
}
