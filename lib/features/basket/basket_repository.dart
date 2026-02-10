import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/price_model.dart';

class BasketItemDescriptor {
  final String key;
  final String? productId;
  final String? barcode;
  final String? name;
  final String? normalizedName;

  const BasketItemDescriptor({
    required this.key,
    this.productId,
    this.barcode,
    this.name,
    this.normalizedName,
  });
}

class BasketPriceFetchResult {
  final Map<String, Map<String, double>> pricesIndex;
  final Map<String, String> marketNames;
  final int priceDocumentCount;

  const BasketPriceFetchResult({
    required this.pricesIndex,
    required this.marketNames,
    required this.priceDocumentCount,
  });
}

class BasketRepository {
  BasketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Map<String, BasketPriceFetchResult> _batchCache = {};

  static const int _chunkSize = 10;

  Future<BasketPriceFetchResult> fetchPricesForBasketItems(
    List<BasketItemDescriptor> items,
  ) async {
    final cacheKey = _cacheKeyFor(items);
    final cached = _batchCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final productIds = <String>{};
    final barcodes = <String>{};
    final names = <String>{};
    for (final item in items) {
      final productId = item.productId?.trim();
      if (productId != null && productId.isNotEmpty) {
        productIds.add(productId);
      }
      final barcode = item.barcode?.trim();
      if (barcode != null && barcode.isNotEmpty) {
        barcodes.add(barcode);
      }
      final name = item.name?.trim();
      if (name != null && name.isNotEmpty) {
        names.add(name);
      }
    }

    final prices = <PriceModel>[];
    prices.addAll(await _fetchPricesByField('productId', productIds.toList()));
    if (barcodes.isNotEmpty) {
      prices.addAll(await _fetchPricesByField('productBarcode', barcodes.toList()));
    }
    if (names.isNotEmpty) {
      prices.addAll(await _fetchPricesByField('productName', names.toList()));
    }

    final Map<String, Map<String, double>> pricesIndex = {
      for (final item in items) item.key: <String, double>{},
    };
    final Map<String, String> marketNames = {};

    final descriptorByKey = {for (final item in items) item.key: item};
    for (final price in prices) {
      final marketId = _marketId(price);
      if (marketId.isEmpty || price.price <= 0) {
        continue;
      }
      marketNames[marketId] = price.storeName?.isNotEmpty == true ? price.storeName! : marketId;

      for (final descriptor in descriptorByKey.values) {
        if (_matchesDescriptor(price, descriptor)) {
          final marketPrices = pricesIndex[descriptor.key] ?? <String, double>{};
          final existing = marketPrices[marketId];
          if (existing == null || price.price < existing) {
            marketPrices[marketId] = price.price;
            pricesIndex[descriptor.key] = marketPrices;
          }
        }
      }
    }

    final result = BasketPriceFetchResult(
      pricesIndex: pricesIndex,
      marketNames: marketNames,
      priceDocumentCount: prices.length,
    );
    _batchCache[cacheKey] = result;
    return result;
  }

  Future<List<PriceModel>> _fetchPricesByField(
    String field,
    List<String> values,
  ) async {
    if (values.isEmpty) return [];
    final results = <PriceModel>[];
    for (var i = 0; i < values.length; i += _chunkSize) {
      final chunk = values.sublist(
        i,
        i + _chunkSize > values.length ? values.length : i + _chunkSize,
      );
      final snapshot = await _firestore
          .collection('prices')
          .where(field, whereIn: chunk)
          .get();
      results.addAll(snapshot.docs.map((doc) => PriceModel.fromFirestore(doc)));
    }
    return results;
  }

  String _cacheKeyFor(List<BasketItemDescriptor> items) {
    final keys = items.map((item) => item.key).toList()..sort();
    return keys.join('|');
  }

  bool _matchesDescriptor(PriceModel price, BasketItemDescriptor descriptor) {
    final productId = descriptor.productId;
    if (productId != null && productId.isNotEmpty) {
      if (price.productId == productId) {
        return true;
      }
    }
    final barcode = descriptor.barcode;
    if (barcode != null && barcode.isNotEmpty) {
      if (price.productBarcode == barcode || price.productId == barcode) {
        return true;
      }
    }
    final normalized = descriptor.normalizedName;
    if (normalized != null && normalized.isNotEmpty) {
      final priceName = price.productName?.trim();
      if (priceName == null || priceName.isEmpty) return false;
      return _normalizeName(priceName) == normalized;
    }
    return false;
  }

  String _marketId(PriceModel price) {
    final storeId = price.storeId.trim();
    if (storeId.isNotEmpty) {
      return storeId;
    }
    return (price.storeName ?? '').trim();
  }

  String _normalizeName(String value) {
    final trimmed = value.trim().toLowerCase();
    final replaced = trimmed
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ş', 's')
        .replaceAll('Ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('Ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('Ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ç', 'c');
    return replaced.replaceAll(RegExp(r'\s+'), ' ');
  }
}
