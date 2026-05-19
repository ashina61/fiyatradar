import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/admin/illustration_picker/illustration_manifest_service.dart';
import '../../features/admin/models/illustration_asset.dart';
import '../../models/product.dart';
import '../../ui/components.dart';
import '../../ui/tokens.dart';

/// Resolves the right visual for a product in a single place:
///   1. `product.imageUrl` (Storage / OpenFoodFacts CDN) if present
///   2. brand-agnostic category illustration via `assignedIllustrationId`
///   3. neutral basket icon as a last resort
///
/// Replaces the legacy emoji-as-visual fallback so the catalog uses real
/// product photography and category artwork end-to-end.
class ProductVisual extends StatelessWidget {
  const ProductVisual({
    super.key,
    required this.product,
    this.size,
    this.fit = BoxFit.cover,
    this.iconColor,
    this.iconSize,
    this.cacheWidth,
    this.padIllustration = true,
  });

  final Product product;
  final double? size;
  final BoxFit fit;
  final Color? iconColor;
  final double? iconSize;
  final int? cacheWidth;
  final bool padIllustration;

  @override
  Widget build(BuildContext context) {
    final url = product.imageUrl;
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          fit: fit,
          cacheWidth: cacheWidth,
          filterQuality: FilterQuality.medium,
          frameBuilder: frFadeFrameBuilder,
          errorBuilder: (_, __, ___) =>
              _IllustrationOrIcon(product: product, padded: padIllustration,
                  iconColor: iconColor, iconSize: iconSize),
        ),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: _IllustrationOrIcon(
        product: product,
        padded: padIllustration,
        iconColor: iconColor,
        iconSize: iconSize,
      ),
    );
  }
}

class _IllustrationOrIcon extends StatelessWidget {
  const _IllustrationOrIcon({
    required this.product,
    required this.padded,
    this.iconColor,
    this.iconSize,
  });

  final Product product;
  final bool padded;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final id = product.assignedIllustrationId;
    final fallback = Center(
      child: Icon(
        Icons.shopping_basket_outlined,
        color: iconColor ?? FR.gold,
        size: iconSize,
      ),
    );
    if (id == null || id.isEmpty) return fallback;
    return FutureBuilder<IllustrationAsset?>(
      future: IllustrationManifestService.findById(id),
      builder: (_, snap) {
        final asset = snap.data;
        if (asset == null) return fallback;
        final svg = SvgPicture.asset(
          asset.assetPath,
          fit: BoxFit.contain,
          semanticsLabel: asset.label,
        );
        return padded
            ? Padding(
                padding: const EdgeInsets.all(6),
                child: svg,
              )
            : svg;
      },
    );
  }
}
