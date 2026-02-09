import '../models/basket_item_model.dart';
import '../models/price_model.dart';
import 'firestore_service.dart';

class BasketCalculationResult {
  final Map<String, double> perStoreTotal;
  final Map<String, int> perStoreCoverage;
  final Map<String, PriceModel> cheapestPerProduct;
  final List<String> missingProductIds;

  BasketCalculationResult({
    required this.perStoreTotal,
    required this.perStoreCoverage,
    required this.cheapestPerProduct,
    required this.missingProductIds,
  });
}

class BasketService {
  final FirestoreService firestoreService;

  BasketService(this.firestoreService);

  Future<BasketCalculationResult> calculateRecommendations(
    List<BasketItemModel> items,
  ) async {
    final productIds = items.map((e) => e.productId).toList();
    final prices = await firestoreService.getPricesForProductIds(productIds);
    final approvedPrices = prices.where((p) => p.isApproved).toList();

    final Map<String, PriceModel> cheapestPerProduct = {};
    final Map<String, Map<String, PriceModel>> cheapestPerStore = {};

    for (final price in approvedPrices) {
      final productId = price.productId;
      final storeKey = price.storeId ?? price.storeName;
      if (storeKey.isEmpty) continue;

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

    for (final item in items) {
      final storeMap = cheapestPerStore[item.productId];
      if (storeMap == null) {
        continue;
      }
      storeMap.forEach((storeKey, price) {
        perStoreTotal[storeKey] =
            (perStoreTotal[storeKey] ?? 0) + price.price * item.quantity;
        perStoreCoverage[storeKey] =
            (perStoreCoverage[storeKey] ?? 0) + 1;
      });
    }

    final missingProductIds = items
        .where((item) => !cheapestPerProduct.containsKey(item.productId))
        .map((item) => item.productId)
        .toList();

    return BasketCalculationResult(
      perStoreTotal: perStoreTotal,
      perStoreCoverage: perStoreCoverage,
      cheapestPerProduct: cheapestPerProduct,
      missingProductIds: missingProductIds,
    );
  }
}
