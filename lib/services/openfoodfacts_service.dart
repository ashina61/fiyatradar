import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight lookup for OpenFoodFacts product metadata via barcode.
///
/// Admin panel uses this to auto-fill the product hero image when an
/// admin types an EAN/UPC barcode while editing a catalog entry. We do
/// not persist any OpenFoodFacts payload — only the public CDN image
/// URL is copied into `products.imageUrl` after admin confirmation.
class OpenFoodFactsService {
  OpenFoodFactsService._();
  static final OpenFoodFactsService instance = OpenFoodFactsService._();

  static const _base = 'https://world.openfoodfacts.org/api/v0/product';
  static const _timeout = Duration(seconds: 8);

  /// Returns `null` when the barcode is unknown or the network call fails.
  /// On success, returns the best available front image URL, preferring
  /// the Turkish localized variant and falling back to the canonical front.
  Future<OpenFoodFactsResult?> lookup(String barcode) async {
    final code = barcode.trim();
    if (code.isEmpty) return null;
    // OpenFoodFacts uses EAN-8/12/13 most commonly. Reject obvious garbage
    // to avoid spamming the public API with 404s.
    if (!RegExp(r'^\d{6,14}$').hasMatch(code)) return null;

    final uri = Uri.parse('$_base/$code.json');
    try {
      final resp = await http
          .get(uri, headers: const {
            'User-Agent': 'FiyatRadar/1.0 (https://fiyatradar.netlify.app)',
            'Accept': 'application/json',
          })
          .timeout(_timeout);
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body);
      if (body is! Map<String, dynamic>) return null;
      final status = body['status'];
      if (status is num && status.toInt() != 1) return null;

      final product = body['product'];
      if (product is! Map<String, dynamic>) return null;

      final imageUrl = _pickImage(product);
      if (imageUrl == null || imageUrl.isEmpty) return null;

      return OpenFoodFactsResult(
        imageUrl: imageUrl,
        productName: _readString(product, const [
          'product_name_tr',
          'product_name',
          'generic_name_tr',
          'generic_name',
        ]),
        brand: _readString(product, const ['brands']),
        quantity: _readString(product, const ['quantity']),
      );
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _pickImage(Map<String, dynamic> product) {
    // Try selected_images.front first — it's the locale-aware, cropped
    // hero photo. Then fall back to image_front_url / image_url.
    final selected = product['selected_images'];
    if (selected is Map) {
      final front = selected['front'];
      if (front is Map) {
        final display = front['display'];
        if (display is Map) {
          for (final lang in const ['tr', 'en', 'fr', 'de']) {
            final v = display[lang];
            if (v is String && v.isNotEmpty) return v;
          }
          // Any first display variant.
          for (final v in display.values) {
            if (v is String && v.isNotEmpty) return v;
          }
        }
      }
    }
    for (final key in const [
      'image_front_url',
      'image_front_small_url',
      'image_url',
      'image_small_url',
    ]) {
      final v = product[key];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  String? _readString(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }
}

class OpenFoodFactsResult {
  final String imageUrl;
  final String? productName;
  final String? brand;
  final String? quantity;

  const OpenFoodFactsResult({
    required this.imageUrl,
    this.productName,
    this.brand,
    this.quantity,
  });
}
