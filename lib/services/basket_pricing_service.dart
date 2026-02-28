import '../models/basket_item_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';

class BasketMarketSummary {
  final String marketName;
  final double total;

  const BasketMarketSummary({
    required this.marketName,
    required this.total,
  });
}

class MixedBasketSummary {
  final double total;
  final List<String> missingProductIds;

  const MixedBasketSummary({
    required this.total,
    required this.missingProductIds,
  });
}

class BasketPricingServiceResult {
  final BasketMarketSummary? bestSingleMarket;
  final MixedBasketSummary mixedBasket;
  final Map<String, int> perMarketMissingCount;

  const BasketPricingServiceResult({
    required this.bestSingleMarket,
    required this.mixedBasket,
    required this.perMarketMissingCount,
  });
}

class BasketPricingService {
  const BasketPricingService._();

  factory BasketPricingService.forTest() => const BasketPricingService._();

  BasketPricingServiceResult calculateFromPrices(
    List<BasketItemModel> items,
    Map<String, ProductModel> _productMap,
    List<PriceModel> prices,
  ) {
    final approved = prices.where((p) => p.isApproved && p.price > 0).toList();

    final storeNames = <String>{
      ...approved.map((p) => (p.storeName ?? '').trim()).where((name) => name.isNotEmpty),
    };

    final Map<String, Map<String, double>> perStoreProductMinPrice = {};
    for (final price in approved) {
      final store = (price.storeName ?? '').trim();
      if (store.isEmpty) continue;
      final productId = price.productId;
      final storeMap = perStoreProductMinPrice.putIfAbsent(store, () => {});
      final existing = storeMap[productId];
      if (existing == null || price.price < existing) {
        storeMap[productId] = price.price;
      }
    }

    final perMarketMissingCount = <String, int>{};
    final perMarketTotals = <String, double>{};

    for (final store in storeNames) {
      double total = 0;
      int missing = 0;
      final storeMap = perStoreProductMinPrice[store] ?? const {};

      for (final item in items) {
        final unit = storeMap[item.productId];
        if (unit == null) {
          missing += 1;
          continue;
        }
        total += unit * item.quantity;
      }

      perMarketMissingCount[store] = missing;
      perMarketTotals[store] = total;
    }

    BasketMarketSummary? bestSingleMarket;
    perMarketTotals.forEach((store, total) {
      final missing = perMarketMissingCount[store] ?? items.length;
      if (missing != 0) return;
      if (bestSingleMarket == null || total < bestSingleMarket!.total) {
        bestSingleMarket = BasketMarketSummary(marketName: store, total: total);
      }
    });

    final cheapestPerProduct = <String, double>{};
    for (final price in approved) {
      final existing = cheapestPerProduct[price.productId];
      if (existing == null || price.price < existing) {
        cheapestPerProduct[price.productId] = price.price;
      }
    }

    double mixedTotal = 0;
    final missingProductIds = <String>[];
    for (final item in items) {
      final unit = cheapestPerProduct[item.productId];
      if (unit == null) {
        missingProductIds.add(item.productId);
      } else {
        mixedTotal += unit * item.quantity;
      }
    }

    return BasketPricingServiceResult(
      bestSingleMarket: bestSingleMarket,
      mixedBasket: MixedBasketSummary(
        total: mixedTotal,
        missingProductIds: missingProductIds,
      ),
      perMarketMissingCount: perMarketMissingCount,
    );
  }
}
