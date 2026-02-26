import '../models/basket_item_model.dart';
import '../models/price_model.dart';
import 'firestore_service.dart';

class BasketCalculationResult {
  final Map<String, double> perStoreTotal;
  final Map<String, int> perStoreCoverage;
  final Map<String, int> perStoreMissingCount;
  final Map<String, PriceModel> cheapestPerProduct;
  final List<String> missingProductIds;
  final double bestMixTotal;

  BasketCalculationResult({
    required this.perStoreTotal,
    required this.perStoreCoverage,
    required this.perStoreMissingCount,
    required this.cheapestPerProduct,
    required this.missingProductIds,
    required this.bestMixTotal,
  });
}

typedef PriceFetcher = Future<List<PriceModel>> Function(List<String> productIds);

class BasketService {
  final FirestoreService? firestoreService;
  final PriceFetcher _priceFetcher;

  BasketService(FirestoreService firestoreService)
      : firestoreService = firestoreService,
        _priceFetcher = firestoreService.getPricesForProductIds;

  BasketService.withPriceFetcher(PriceFetcher priceFetcher)
      : firestoreService = null,
        _priceFetcher = priceFetcher;

  Future<BasketCalculationResult> calculateRecommendations(
    List<BasketItemModel> items,
  ) async {
    final productIds = items.map((e) => e.productId).toList();
    final prices = await _priceFetcher(productIds);
    final approvedPrices = prices.where((p) => p.isApproved).toList();

    final Map<String, PriceModel> cheapestPerProduct = {};
    final Map<String, Map<String, PriceModel>> cheapestPerStore = {};
    final Set<String> storeKeys = {};

    for (final price in approvedPrices) {
      if (price.price <= 0) {
        continue;
      }
      final productId = price.productId;
      final storeKey = price.storeId ?? price.storeName;
      if (storeKey.isEmpty) continue;
      storeKeys.add(storeKey);

      final currentCheapest = cheapestPerProduct[productId];
      if (currentCheapest == null || price.price < currentCheapest.price) {
        cheapestPerProduct[productId] = price;
      }

      final storeMap = cheapestPerStore.putIfAbsent(productId, () => {});
      final existing = storeMap[storeKey];
      if (existing == null || price.price < existing.price) {
        storeMap[storeKey] = price;
      }
    }

    final Map<String, double> perStoreTotal = {};
    final Map<String, int> perStoreCoverage = {};
    final Map<String, int> perStoreMissingCount = {};

    for (final storeKey in storeKeys) {
      perStoreTotal[storeKey] = 0;
      perStoreCoverage[storeKey] = 0;
      perStoreMissingCount[storeKey] = 0;
    }

    for (final item in items) {
      final storeMap = cheapestPerStore[item.productId];
      for (final storeKey in storeKeys) {
        final price = storeMap?[storeKey];
        if (price == null) {
          perStoreMissingCount[storeKey] =
              (perStoreMissingCount[storeKey] ?? 0) + 1;
        } else {
          perStoreTotal[storeKey] =
              (perStoreTotal[storeKey] ?? 0) + price.price * item.quantity;
          perStoreCoverage[storeKey] =
              (perStoreCoverage[storeKey] ?? 0) + 1;
        }
      }
    }

    final missingProductIds = items
        .where((item) => !cheapestPerProduct.containsKey(item.productId))
        .map((item) => item.productId)
        .toList();

    double bestMixTotal = 0;
    for (final item in items) {
      final cheapest = cheapestPerProduct[item.productId];
      if (cheapest == null) continue;
      bestMixTotal += cheapest.price * item.quantity;
    }

    return BasketCalculationResult(
      perStoreTotal: perStoreTotal,
      perStoreCoverage: perStoreCoverage,
      perStoreMissingCount: perStoreMissingCount,
      cheapestPerProduct: cheapestPerProduct,
      missingProductIds: missingProductIds,
      bestMixTotal: bestMixTotal,
    );
  }
}
