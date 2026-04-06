import 'package:flutter/material.dart';

import 'fr_pill.dart';

class FRLevelBadge extends StatelessWidget {
  const FRLevelBadge(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => FRPill(label, variant: FRPillVariant.gold);
}
