import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRProgressBar extends StatelessWidget {
  const FRProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: FRDsColors.frSurfaceMuted,
        valueColor: const AlwaysStoppedAnimation(FRDsColors.frBrown),
      ),
    );
  }
}
