import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';
import '../tokens/typography.dart';

enum FRPillVariant { gold, soft, dark, selected, muted }

class FRPill extends StatelessWidget {
  const FRPill(this.text, {super.key, this.variant = FRPillVariant.soft});

  final String text;
  final FRPillVariant variant;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (variant) {
      FRPillVariant.gold => (FRDsColors.frGoldSoft, FRDsColors.frBrownDeep),
      FRPillVariant.dark => (FRDsColors.frSurfaceDark, FRDsColors.frSurface),
      FRPillVariant.selected => (FRDsColors.frBrownDeep, FRDsColors.frSurface),
      FRPillVariant.muted => (FRDsColors.frSurfaceMuted, FRDsColors.frTextSecondary),
      FRPillVariant.soft => (FRDsColors.frSurface, FRDsColors.frTextPrimary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bg, borderRadius: FRDsRadius.pill),
      child: Text(text, style: FRDsTypography.labelCapsule.copyWith(color: fg)),
    );
  }
}
