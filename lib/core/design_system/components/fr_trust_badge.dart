import 'package:flutter/material.dart';

import 'fr_pill.dart';

class FRTrustBadge extends StatelessWidget {
  const FRTrustBadge({required this.score, super.key});

  final int score;

  @override
  Widget build(BuildContext context) => FRPill('Güven %$score', variant: FRPillVariant.selected);
}
