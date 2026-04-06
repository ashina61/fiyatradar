import 'package:flutter/material.dart';

import 'fr_surface_card.dart';
import '../tokens/typography.dart';
import '../tokens/spacing.dart';

class FRStatCard extends StatelessWidget {
  const FRStatCard({required this.value, required this.label, super.key, this.description});

  final String value;
  final String label;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return FRSurfaceCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: FRDsTypography.displayMedium),
        const SizedBox(height: FRDsSpacing.space8),
        Text(label, style: FRDsTypography.titleMedium),
        if (description != null) ...[
          const SizedBox(height: FRDsSpacing.space4),
          Text(description!, style: FRDsTypography.bodyMedium),
        ]
      ]),
    );
  }
}
