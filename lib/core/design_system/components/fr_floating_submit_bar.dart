import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/shadows.dart';
import 'fr_primary_button.dart';

class FRFloatingSubmitBar extends StatelessWidget {
  const FRFloatingSubmitBar({required this.label, required this.onPressed, super.key, this.child});

  final String label;
  final VoidCallback? onPressed;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: FRDsColors.frSurface, boxShadow: FRDsShadows.shadowFloating),
      child: child ?? FRPrimaryButton(label: label, onPressed: onPressed),
    );
  }
}
