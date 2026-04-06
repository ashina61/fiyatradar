import 'package:flutter/material.dart';

import '../tokens/typography.dart';
import '../tokens/spacing.dart';

class FRMetricBlock extends StatelessWidget {
  const FRMetricBlock({required this.value, required this.label, super.key});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: FRDsTypography.titleLarge),
      const SizedBox(height: FRDsSpacing.space4),
      Text(label, style: FRDsTypography.bodyMedium),
    ]);
  }
}
