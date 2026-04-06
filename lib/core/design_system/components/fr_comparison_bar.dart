import 'package:flutter/material.dart';

import '../tokens/colors.dart';

class FRComparisonBar extends StatelessWidget {
  const FRComparisonBar({required this.left, required this.right, super.key});

  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    final total = (left + right) == 0 ? 1.0 : left + right;
    return Row(children: [
      Expanded(flex: (left / total * 1000).round(), child: Container(height: 10, color: FRDsColors.frBrownDeep)),
      Expanded(flex: (right / total * 1000).round(), child: Container(height: 10, color: FRDsColors.frGoldSoft)),
    ]);
  }
}
