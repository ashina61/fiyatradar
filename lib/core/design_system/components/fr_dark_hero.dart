import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/spacing.dart';
import '../tokens/typography.dart';

class FRDarkHero extends StatelessWidget {
  const FRDarkHero({
    required this.title,
    super.key,
    this.subtitle,
    this.kicker,
    this.leading,
    this.actions = const [],
    this.content,
  });

  final String title;
  final String? subtitle;
  final Widget? kicker;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? content;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(FRDsSpacing.space20),
      decoration: const BoxDecoration(
        color: FRDsColors.frSurfaceDark,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(FRDsRadius.radiusXl),
          bottomRight: Radius.circular(FRDsRadius.radiusXl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) leading!,
              const Spacer(),
              ...actions,
            ],
          ),
          if (kicker != null) ...[
            const SizedBox(height: FRDsSpacing.space12),
            kicker!,
          ],
          const SizedBox(height: FRDsSpacing.space12),
          Text(title, style: FRDsTypography.displayMedium.copyWith(color: FRDsColors.frSurface)),
          if (subtitle != null) ...[
            const SizedBox(height: FRDsSpacing.space8),
            Text(subtitle!, style: FRDsTypography.bodyMedium.copyWith(color: FRDsColors.frGoldSoft)),
          ],
          if (content != null) ...[
            const SizedBox(height: FRDsSpacing.space16),
            content!,
          ],
        ],
      ),
    );
  }
}
