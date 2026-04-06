import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class FRKickerPill extends StatelessWidget {
  const FRKickerPill(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: FRDsSpacing.space12, vertical: FRDsSpacing.space8),
      decoration: const BoxDecoration(
        color: FRDsColors.frGoldSoft,
        borderRadius: FRDsRadius.pill,
      ),
      child: Text(label, style: FRDsTypography.labelCapsule.copyWith(color: FRDsColors.frBrownDeep)),
    );
  }
}
