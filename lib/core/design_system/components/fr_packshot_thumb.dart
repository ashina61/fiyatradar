import 'package:flutter/material.dart';

import '../tokens/colors.dart';
import '../tokens/radius.dart';

class FRPackshotThumb extends StatelessWidget {
  const FRPackshotThumb({super.key, this.imageUrl, this.size = 48});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: FRDsRadius.sm,
      child: Container(
        width: size,
        height: size,
        color: FRDsColors.frSurfaceMuted,
        child: imageUrl == null ? const Icon(Icons.shopping_bag_outlined) : Image.network(imageUrl!, fit: BoxFit.cover),
      ),
    );
  }
}
