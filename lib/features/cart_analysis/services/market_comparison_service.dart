import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';
import '../models/market_comparison.dart';

class MarketComparisonService {
  const MarketComparisonService(this._firestore);

  final FirebaseFirestore _firestore;

  Future<MarketComparisonBundle> compare(List<CartItem> items) async {
    if (items.isEmpty) {
      return const MarketComparisonBundle(winner: null, alternatives: [], savingAmount: 0);
    }

    final productIds = items.map((e) => e.productId).toSet().toList();
    final marketSnapshot = await _firestore.collection('markets').get();
    final priceSnapshot = await _firestore
        .collection('market_prices')
        .where('productId', whereIn: productIds.take(10).toList())
        .get();

    final marketNameById = {
      for (final doc in marketSnapshot.docs)
        doc.id: (doc.data()['name'] as String?) ?? 'Market',
    };
    final marketDistanceById = {
      for (final doc in marketSnapshot.docs)
        doc.id: (doc.data()['distanceKm'] as num?)?.toDouble() ?? 0,
    };

    final pricesByMarket = <String, Map<String, double>>{};
    for (final doc in priceSnapshot.docs) {
      final data = doc.data();
      final marketId = (data['marketId'] as String?) ?? '';
      final productId = (data['productId'] as String?) ?? '';
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      if (marketId.isEmpty || productId.isEmpty) continue;
      pricesByMarket.putIfAbsent(marketId, () => {})[productId] = price;
    }

    final lowestByProduct = <String, double>{};
    for (final item in items) {
      final allProductPrices = pricesByMarket.values
          .map((marketMap) => marketMap[item.productId])
          .whereType<double>()
          .toList();
      if (allProductPrices.isNotEmpty) {
        allProductPrices.sort();
        lowestByProduct[item.productId] = allProductPrices.first;
      }
    }

    final comparisons = <MarketComparison>[];
    for (final entry in pricesByMarket.entries) {
      final marketId = entry.key;
      final marketPrices = entry.value;
      var total = 0.0;
      var allProductsExist = true;
      final diffs = <ProductPriceDiff>[];

      for (final item in items) {
        final marketPrice = marketPrices[item.productId];
        if (marketPrice == null) {
          allProductsExist = false;
          continue;
        }
        total += marketPrice * item.quantity;
        final cheapest = lowestByProduct[item.productId] ?? marketPrice;
        diffs.add(
          ProductPriceDiff(
            productId: item.productId,
            productName: item.productName,
            marketPrice: marketPrice,
            cheapestPrice: cheapest,
          ),
        );
      }

      comparisons.add(
        MarketComparison(
          marketId: marketId,
          marketName: marketNameById[marketId] ?? 'Market',
          distanceKm: marketDistanceById[marketId] ?? 0,
          total: total,
          hasAllProducts: allProductsExist,
          productDiffs: diffs,
        ),
      );
    }

    comparisons.sort((a, b) {
      if (a.hasAllProducts != b.hasAllProducts) {
        return a.hasAllProducts ? -1 : 1;
      }
      return a.total.compareTo(b.total);
    });

    if (comparisons.isEmpty) {
      return const MarketComparisonBundle(winner: null, alternatives: [], savingAmount: 0);
    }

    final winner = comparisons.first;
    final second = comparisons.length > 1 ? comparisons[1] : null;

    return MarketComparisonBundle(
      winner: winner,
      alternatives: comparisons.skip(1).toList(),
      savingAmount: second == null ? 0 : (second.total - winner.total).clamp(0, double.infinity),
    );
  }
}
