import 'package:flutter/material.dart';

import '../tokens/typography.dart';
import '../tokens/spacing.dart';

class FRSectionHeader extends StatelessWidget {
  const FRSectionHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(eyebrow!.toUpperCase(), style: FRDsTypography.sectionEyebrow),
                const SizedBox(height: FRDsSpacing.space8),
              ],
              Text(title, style: FRDsTypography.titleLarge),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: FRDsSpacing.space12),
          trailing!,
        ],
      ],
    );
  }
}
