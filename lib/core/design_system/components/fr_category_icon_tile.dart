import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRCategoryIconTile extends StatelessWidget {
  const FRCategoryIconTile({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(color: FRDsColors.frSurface, borderRadius: FRDsRadius.md),
        child: Icon(icon, color: FRDsColors.frBrownDeep),
      ),
      const SizedBox(height: 8),
      Text(label),
    ]);
  }
}
