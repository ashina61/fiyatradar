import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../features/admin/illustration_picker/illustration_manifest_service.dart';
import '../../features/admin/models/illustration_asset.dart';
import '../../models/product.dart';
import '../../ui/components.dart';

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
///   2. Within the product's category: the illustration whose label/tags best
///      match the product name (e.g. "Muz" → meyve-muz, "Kola" → karbonatlı)
///   3. Within the category: a deterministic spread by product so different
///      products don't all collapse onto the same artwork
///   4. `diger-genel` fallback
///   5. First illustration in the manifest
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
    final inCat = manifest.illustrations
        .where((a) => a.category == manifestCat)
        .toList(growable: false);
    if (inCat.isNotEmpty) {
      // Ürün adıyla en iyi eşleşen (etiket + tag) görseli seç; bulunamazsa
      // kategori içinde ürüne göre deterministik dağıt — böylece aynı
      // kategorideki ürünler tek bir görsele yığılmaz.
      final matched = _bestNameMatch(inCat, product);
      if (matched != null) return matched;
      return inCat[_stableHash(product.id.isNotEmpty ? product.id : product.name) % inCat.length];
    }
  }

  for (final a in manifest.illustrations) {
    if (a.id == 'diger-genel') return a;
  }
  return manifest.illustrations.isNotEmpty
      ? manifest.illustrations.first
      : null;
}

/// Ürün adını, kategori içindeki illüstrasyonların `label` + `tags`
/// kelimeleriyle karşılaştırır. En uzun (en spesifik) tam-kelime eşleşmesi
/// kazanır; eşleşme yoksa `null`.
IllustrationAsset? _bestNameMatch(
    List<IllustrationAsset> inCat, Product product) {
  final name = _foldTr(product.name);
  if (name.trim().isEmpty) return null;
  IllustrationAsset? best;
  var bestScore = 0;
  for (final a in inCat) {
    var score = 0;
    for (final candidate in <String>[a.label, ...a.tags]) {
      final key = _foldTr(candidate).trim();
      if (key.length < 2) continue;
      if (key.length > score && _containsWord(name, key)) {
        score = key.length;
      }
    }
    if (score > bestScore) {
      bestScore = score;
      best = a;
    }
  }
  return best;
}

/// `needle`'ı `haystack` içinde KELİME sınırında arar (alt-dize yanlış
/// eşleşmelerini önler: "su" → "sucuk" eşleşmesin).
bool _containsWord(String haystack, String needle) {
  var start = 0;
  while (true) {
    final i = haystack.indexOf(needle, start);
    if (i < 0) return false;
    final before = i == 0 ? '' : haystack[i - 1];
    final endIdx = i + needle.length;
    final after = endIdx >= haystack.length ? '' : haystack[endIdx];
    if (!_isWordChar(before) && !_isWordChar(after)) return true;
    start = i + 1;
  }
}

bool _isWordChar(String c) {
  if (c.isEmpty) return false;
  final u = c.codeUnitAt(0);
  return (u >= 97 && u <= 122) || (u >= 48 && u <= 57); // a-z, 0-9
}

/// Türkçe karakterleri ASCII'ye katlayıp küçük harfe çevirir; eşleştirmeyi
/// büyük/küçük harf ve aksandan bağımsız yapar.
String _foldTr(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    switch (ch) {
      case 'ç':
      case 'Ç':
        buf.write('c');
        break;
      case 'ğ':
      case 'Ğ':
        buf.write('g');
        break;
      case 'ı':
      case 'I':
        buf.write('i');
        break;
      case 'i':
      case 'İ':
        buf.write('i');
        break;
      case 'ö':
      case 'Ö':
        buf.write('o');
        break;
      case 'ş':
      case 'Ş':
        buf.write('s');
        break;
      case 'ü':
      case 'Ü':
        buf.write('u');
        break;
      default:
        buf.write(ch.toLowerCase());
    }
  }
  return buf.toString();
}

/// Platform/oturumdan bağımsız deterministik hash — görsel atamasının her
/// açılışta aynı kalması için `String.hashCode` yerine kullanılır.
int _stableHash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}
