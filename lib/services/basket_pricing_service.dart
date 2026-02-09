import 'package:flutter/foundation.dart';
import '../models/basket_item_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import 'firestore_service.dart';

class BestSingleMarketResult {
  final String marketKey;
  final String marketName;
  final double total;

  BestSingleMarketResult({
    required this.marketKey,
    required this.marketName,
    required this.total,
  });
}

class CheapestItemPrice {
  final String marketKey;
  final String marketName;
  final double price;

  const CheapestItemPrice({
    required this.marketKey,
    required this.marketName,
    required this.price,
  });
}

class MixedBasketResult {
  final double total;
  final Map<String, CheapestItemPrice> perItemCheapest;
  final List<String> missingProductIds;

  MixedBasketResult({
    required this.total,
    required this.perItemCheapest,
    required this.missingProductIds,
  });
}

class BasketPricingResult {
  final BestSingleMarketResult? bestSingleMarket;
  final MixedBasketResult mixedBasket;
  final Map<String, double> perMarketTotals;
  final Map<String, int> perMarketMissingCount;
  final Map<String, String> marketNames;

  BasketPricingResult({
    required this.bestSingleMarket,
    required this.mixedBasket,
    required this.perMarketTotals,
    required this.perMarketMissingCount,
    required this.marketNames,
  });
}

class BasketPricingService {
  final FirestoreService? firestoreService;
  final Map<String, List<PriceModel>> _priceCache = {};

  BasketPricingService(this.firestoreService);

  BasketPricingService.forTest() : firestoreService = null;

  Future<BasketPricingResult> calculateRecommendations(
    List<BasketItemModel> items,
    Map<String, ProductModel> productMap,
  ) async {
    final service = firestoreService;
    if (service == null) {
      throw StateError('FirestoreService must be provided for live calculations.');
    }
    final keys = _collectProductKeys(items, productMap);
    final prices = await _fetchPricesForKeys(service, keys);
    return calculateFromPrices(items, productMap, prices);
  }

  BasketPricingResult calculateFromPrices(
    List<BasketItemModel> items,
    Map<String, ProductModel> productMap,
    List<PriceModel> prices,
  ) {
    final approvedPrices = prices.where((p) => p.isApproved && p.price > 0).toList();
    final Map<String, List<PriceModel>> pricesByKey = {};
    final Map<String, String> marketNames = {};

    for (final price in approvedPrices) {
      final storeKey = _storeKey(price);
      if (storeKey.isEmpty) continue;
      marketNames[storeKey] = price.storeName.isNotEmpty ? price.storeName : storeKey;
      for (final key in _priceMatchKeys(price)) {
        final list = pricesByKey.putIfAbsent(key, () => []);
        list.add(price);
      }
    }

    final Map<String, double> perMarketTotals = {};
    final Map<String, int> perMarketMissingCount = {};
    final Map<String, CheapestItemPrice> perItemCheapest = {};
    final List<String> missingProductIds = [];

    for (final item in items) {
      final product = productMap[item.productId];
      final matchKeys = _itemMatchKeys(item, product);
      final matchedPrices = _matchPricesByPriority(pricesByKey, matchKeys);

      if (matchedPrices.isEmpty) {
        missingProductIds.add(item.productId);
        debugPrint(
          '[BasketPricing] fiyat bulunamadi: productId=${item.productId}, '
          'barcode=${product?.barcode ?? '-'}, name=${product?.name ?? '-'}',
        );
        continue;
      }

      final Map<String, PriceModel> cheapestPerMarket = {};
      for (final price in matchedPrices) {
        final storeKey = _storeKey(price);
        if (storeKey.isEmpty) continue;
        final existing = cheapestPerMarket[storeKey];
        if (existing == null || price.price < existing.price) {
          cheapestPerMarket[storeKey] = price;
        }
      }

      for (final entry in cheapestPerMarket.entries) {
        final storeKey = entry.key;
        perMarketTotals[storeKey] = (perMarketTotals[storeKey] ?? 0) +
            entry.value.price * item.quantity;
      }

      final cheapestPrice = matchedPrices.reduce(
        (a, b) => a.price <= b.price ? a : b,
      );
      perItemCheapest[item.productId] = CheapestItemPrice(
        marketKey: _storeKey(cheapestPrice),
        marketName: cheapestPrice.storeName,
        price: cheapestPrice.price,
      );
    }

    final storeKeys = perMarketTotals.keys.toSet();
    for (final storeKey in storeKeys) {
      perMarketMissingCount[storeKey] = 0;
    }
    for (final item in items) {
      final product = productMap[item.productId];
      final matchKeys = _itemMatchKeys(item, product);
      final matchedPrices = _matchPricesByPriority(pricesByKey, matchKeys);
      final storesWithPrice = matchedPrices.map(_storeKey).where((key) => key.isNotEmpty).toSet();
      for (final storeKey in storeKeys) {
        if (!storesWithPrice.contains(storeKey)) {
          perMarketMissingCount[storeKey] = (perMarketMissingCount[storeKey] ?? 0) + 1;
        }
      }
    }

    BestSingleMarketResult? bestSingleMarket;
    for (final entry in perMarketTotals.entries) {
      final missing = perMarketMissingCount[entry.key] ?? 0;
      if (missing > 0) continue;
      if (bestSingleMarket == null || entry.value < bestSingleMarket.total) {
        bestSingleMarket = BestSingleMarketResult(
          marketKey: entry.key,
          marketName: marketNames[entry.key] ?? entry.key,
          total: entry.value,
        );
      }
    }

    double mixedTotal = 0;
    for (final item in items) {
      final cheapest = perItemCheapest[item.productId];
      if (cheapest == null) continue;
      mixedTotal += cheapest.price * item.quantity;
    }

    return BasketPricingResult(
      bestSingleMarket: bestSingleMarket,
      mixedBasket: MixedBasketResult(
        total: mixedTotal,
        perItemCheapest: perItemCheapest,
        missingProductIds: missingProductIds,
      ),
      perMarketTotals: perMarketTotals,
      perMarketMissingCount: perMarketMissingCount,
      marketNames: marketNames,
    );
  }

  Future<List<PriceModel>> _fetchPricesForKeys(
    FirestoreService service,
    List<String> keys,
  ) async {
    final missingKeys = keys.where((key) => !_priceCache.containsKey(key)).toList();
    if (missingKeys.isNotEmpty) {
      final results = await service.getPricesForProductKeys(missingKeys);
      for (final price in results) {
        final key = price.productId;
        final list = _priceCache.putIfAbsent(key, () => []);
        list.add(price);
      }
      for (final key in missingKeys) {
        _priceCache.putIfAbsent(key, () => []);
      }
    }

    final Map<String, PriceModel> unique = {};
    for (final key in keys) {
      for (final price in _priceCache[key] ?? []) {
        unique[price.id] = price;
      }
    }
    return unique.values.toList();
  }

  List<String> _collectProductKeys(
    List<BasketItemModel> items,
    Map<String, ProductModel> productMap,
  ) {
    final keys = <String>{};
    for (final item in items) {
      keys.add(item.productId);
      final product = productMap[item.productId];
      final barcode = product?.barcode?.trim();
      if (barcode != null && barcode.isNotEmpty) {
        keys.add(barcode);
      }
      final name = product?.name.trim();
      if (name != null && name.isNotEmpty) {
        keys.add(name);
        keys.add(_normalizeName(name));
      }
    }
    return keys.toList();
  }

  _ItemMatchKeys _itemMatchKeys(BasketItemModel item, ProductModel? product) {
    final barcode = product?.barcode?.trim();
    final name = product?.name.trim();
    return _ItemMatchKeys(
      productId: item.productId,
      barcode: barcode != null && barcode.isNotEmpty ? barcode : null,
      name: name != null && name.isNotEmpty ? name : null,
      normalizedName: name != null && name.isNotEmpty ? _normalizeName(name) : null,
    );
  }

  List<PriceModel> _matchPricesByPriority(
    Map<String, List<PriceModel>> pricesByKey,
    _ItemMatchKeys keys,
  ) {
    final productMatches = pricesByKey[keys.productId] ?? [];
    if (productMatches.isNotEmpty) {
      return productMatches;
    }
    if (keys.barcode != null) {
      final barcodeMatches = pricesByKey[keys.barcode!] ?? [];
      if (barcodeMatches.isNotEmpty) {
        return barcodeMatches;
      }
    }
    final nameMatches = <PriceModel>[];
    if (keys.name != null) {
      nameMatches.addAll(pricesByKey[keys.name!] ?? []);
    }
    if (keys.normalizedName != null) {
      nameMatches.addAll(pricesByKey[keys.normalizedName!] ?? []);
    }
    return nameMatches;
  }

  List<String> _priceMatchKeys(PriceModel price) {
    final keys = <String>{};
    if (price.productId.isNotEmpty) {
      keys.add(price.productId);
      keys.add(_normalizeName(price.productId));
    }
    final barcode = price.productBarcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      keys.add(barcode);
    }
    final name = price.productName?.trim();
    if (name != null && name.isNotEmpty) {
      keys.add(name);
      keys.add(_normalizeName(name));
    }
    return keys.toList();
  }

  String _storeKey(PriceModel price) {
    final storeId = price.storeId?.trim();
    if (storeId != null && storeId.isNotEmpty) {
      return storeId;
    }
    return price.storeName.trim();
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

class _ItemMatchKeys {
  final String productId;
  final String? barcode;
  final String? name;
  final String? normalizedName;

  _ItemMatchKeys({
    required this.productId,
    this.barcode,
    this.name,
    this.normalizedName,
  });
}
