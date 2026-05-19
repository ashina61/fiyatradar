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
    return FutureBuilder<IllustrationManifest>(
      future: IllustrationManifestService.load(),
      builder: (_, snap) {
        final manifest = snap.data;
        if (manifest == null) return const SizedBox.shrink();
        final asset = resolveProductIllustration(manifest, product);
        if (asset == null) return const SizedBox.shrink();
        final svg = SvgPicture.asset(
          asset.assetPath,
          fit: BoxFit.contain,
          semanticsLabel: asset.label,
        );
        return padded
            ? Padding(padding: const EdgeInsets.all(6), child: svg)
            : svg;
      },
    );
  }
}

/// Maps a product's Turkish category label to a manifest category id.
const Map<String, String> _categoryToManifestId = {
  'İçecek': 'icecek',
  'İçecekler': 'icecek',
  'Kahvaltılık': 'kahvalti',
  'Meyve & Sebze': 'meyve',
  'Meyve': 'meyve',
  'Sebze': 'sebze',
  'Atıştırmalık': 'atistirmalik',
  'Süt Ürünleri': 'sut',
  'Temizlik': 'temizlik',
  'Et & Balık': 'et',
  'Et': 'et',
  'Temel Gıda': 'gida',
  'Yağ & Sirke': 'yag',
  'Diğer': 'diger',
};

/// Resolves the best brand-agnostic illustration for a product:
///   1. Explicit `assignedIllustrationId` match
///   2. First illustration matching the product's category
///   3. `diger-genel` fallback
///   4. First illustration in the manifest
/// Always returns a non-null asset when the manifest has any entries —
/// callers can render the result directly without an icon fallback.
IllustrationAsset? resolveProductIllustration(
    IllustrationManifest manifest, Product product) {
  final id = product.assignedIllustrationId;
  if (id != null && id.isNotEmpty) {
    for (final a in manifest.illustrations) {
      if (a.id == id) return a;
    }
  }
  final manifestCat = _categoryToManifestId[product.category];
  if (manifestCat != null) {
    for (final a in manifest.illustrations) {
      if (a.category == manifestCat) return a;
    }
  }
  for (final a in manifest.illustrations) {
    if (a.id == 'diger-genel') return a;
  }
  return manifest.illustrations.isNotEmpty
      ? manifest.illustrations.first
      : null;
}
