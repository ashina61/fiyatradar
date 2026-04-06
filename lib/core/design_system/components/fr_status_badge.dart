import 'package:flutter/material.dart';

import 'fr_pill.dart';

class FRStatusBadge extends StatelessWidget {
  const FRStatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) => FRPill(status, variant: FRPillVariant.muted);
}
