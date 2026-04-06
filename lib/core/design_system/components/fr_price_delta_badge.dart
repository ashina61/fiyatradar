import 'package:flutter/material.dart';

import 'fr_pill.dart';

enum FRPriceDeltaVariant { positive, negative, neutral }

class FRPriceDeltaBadge extends StatelessWidget {
  const FRPriceDeltaBadge({required this.label, required this.variant, super.key});

  final String label;
  final FRPriceDeltaVariant variant;

  @override
  Widget build(BuildContext context) {
    final pillVariant = switch (variant) {
      FRPriceDeltaVariant.positive => FRPillVariant.gold,
      FRPriceDeltaVariant.negative => FRPillVariant.dark,
      FRPriceDeltaVariant.neutral => FRPillVariant.soft,
    };
    return FRPill(label, variant: pillVariant);
  }
}
