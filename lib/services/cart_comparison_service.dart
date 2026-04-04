import '../models/basket_item_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';

class CartMarketProductPrice {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final bool isVerified;

  const CartMarketProductPrice({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.isVerified,
  });
}

class CartMarketComparison {
  final String marketId;
  final String marketName;
  final double total;
  final List<String> missingProductIds;
  final List<CartMarketProductPrice> lines;
  final double? distanceKm;
  final bool hasUnverifiedPrices;

  const CartMarketComparison({
    required this.marketId,
    required this.marketName,
    required this.total,
    required this.missingProductIds,
    required this.lines,
    this.distanceKm,
    this.hasUnverifiedPrices = false,
  });

  bool get hasMissingProducts => missingProductIds.isNotEmpty;
}

class CartComparisonResult {
  final CartMarketComparison? bestMarket;
  final CartMarketComparison? nearestMarket;
  final List<CartMarketComparison> sortedMarkets;
  final String? notice;

  const CartComparisonResult({
    required this.bestMarket,
    required this.nearestMarket,
    required this.sortedMarkets,
    this.notice,
  });

  List<CartMarketComparison> get lowestThree => sortedMarkets.take(3).toList();
}

class CartComparisonService {
  const CartComparisonService();

  CartComparisonResult compare({
    required List<BasketItemModel> items,
    required Map<String, ProductModel> productMap,
    required Map<String, Map<String, PriceModel>> latestPricesByItem,
    required Map<String, String> marketNames,
    required List<StoreModel> stores,
    Set<String>? allowedMarketIds,
  }) {
    final storeById = {for (final store in stores) store.id: store};
    final allMarketIds = <String>{
      for (final marketMap in latestPricesByItem.values) ...marketMap.keys,
    };
    if (allowedMarketIds != null && allowedMarketIds.isNotEmpty) {
      allMarketIds.removeWhere((marketId) => !allowedMarketIds.contains(marketId));
    }

    final comparisons = <CartMarketComparison>[];
    for (final marketId in allMarketIds) {
      final lines = <CartMarketProductPrice>[];
      final missing = <String>[];
      var total = 0.0;
      var hasUnverified = false;

      for (final item in items) {
        final price = latestPricesByItem[item.productId]?[marketId];
        if (price == null) {
          missing.add(item.productId);
          continue;
        }
        final unitPrice = price.price;
        final lineTotal = unitPrice * item.quantity;
        total += lineTotal;
        lines.add(
          CartMarketProductPrice(
            productId: item.productId,
            productName: productMap[item.productId]?.name ?? 'Ürün',
            quantity: item.quantity,
            unitPrice: unitPrice,
            lineTotal: lineTotal,
            isVerified: price.isApproved,
          ),
        );
        if (!price.isApproved) {
          hasUnverified = true;
        }
      }

      comparisons.add(
        CartMarketComparison(
          marketId: marketId,
          marketName: marketNames[marketId] ?? storeById[marketId]?.displayName ?? marketId,
          total: total,
          missingProductIds: missing,
          lines: lines,
          distanceKm: null,
          hasUnverifiedPrices: hasUnverified,
        ),
      );
    }

    comparisons.sort((a, b) {
      if (a.hasMissingProducts != b.hasMissingProducts) {
        return a.hasMissingProducts ? 1 : -1;
      }
      return a.total.compareTo(b.total);
    });

    CartMarketComparison? best;
    for (final comparison in comparisons) {
      if (!comparison.hasMissingProducts) {
        best = comparison;
        break;
      }
    }
    final notice = comparisons.isEmpty
        ? 'Sepetteki ürünler için fiyat bulunamadı.'
        : null;

    return CartComparisonResult(
      bestMarket: best,
      nearestMarket: null,
      sortedMarkets: comparisons,
      notice: notice,
    );
  }

  Map<String, PriceModel?> buildLatestProductPrices({
    required List<BasketItemModel> items,
    required Map<String, Map<String, PriceModel>> latestPricesByItem,
  }) {
    final output = <String, PriceModel?>{};
    for (final item in items) {
      final prices = latestPricesByItem[item.productId]?.values.toList() ?? const <PriceModel>[];
      if (prices.isEmpty) {
        output[item.productId] = null;
        continue;
      }
      prices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      output[item.productId] = prices.first;
    }
    return output;
  }
}
