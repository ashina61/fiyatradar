import 'package:flutter/material.dart';

import 'fr_surface_card.dart';
import '../tokens/spacing.dart';

enum FRProductCardVariant { discoverItem, basketItem, compareItem, selectedProduct }

class FRProductCard extends StatelessWidget {
  const FRProductCard({required this.title, super.key, this.subtitle, this.trailing, this.variant = FRProductCardVariant.discoverItem});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final FRProductCardVariant variant;

  @override
  Widget build(BuildContext context) {
    return FRSurfaceCard(
      child: Row(children: [
        const Icon(Icons.inventory_2_outlined),
        const SizedBox(width: FRDsSpacing.space12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title), if (subtitle != null) Text(subtitle!)])),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
