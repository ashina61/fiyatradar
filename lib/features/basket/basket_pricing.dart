class BasketItemInput {
  final String key;
  final String name;
  final int quantity;

  const BasketItemInput({
    required this.key,
    required this.name,
    required this.quantity,
  });
}

class BasketBestSingleMarketResult {
  final String marketId;
  final String marketName;
  final double total;

  const BasketBestSingleMarketResult({
    required this.marketId,
    required this.marketName,
    required this.total,
  });
}

class BasketItemChoice {
  final String marketId;
  final String marketName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  const BasketItemChoice({
    required this.marketId,
    required this.marketName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}

class BasketMixedResult {
  final double total;
  final Map<String, BasketItemChoice> perItemChoice;
  final List<String> missingKeys;

  const BasketMixedResult({
    required this.total,
    required this.perItemChoice,
    required this.missingKeys,
  });
}

class BasketMarketTotal {
  final double total;
  final List<String> missingKeys;

  const BasketMarketTotal({
    required this.total,
    required this.missingKeys,
  });
}

class BasketPricingSummary {
  final BasketBestSingleMarketResult? bestSingleMarket;
  final BasketMixedResult mixedResult;
  final Map<String, BasketMarketTotal> perMarketTotals;

  const BasketPricingSummary({
    required this.bestSingleMarket,
    required this.mixedResult,
    required this.perMarketTotals,
  });
}

BasketPricingSummary calculateBasketPricing({
  required List<BasketItemInput> items,
  required Map<String, Map<String, double>> pricesIndex,
  required Map<String, String> marketNames,
}) {
  final marketIds = <String>{};
  for (final marketMap in pricesIndex.values) {
    marketIds.addAll(marketMap.keys);
  }

  final perMarketTotals = <String, BasketMarketTotal>{};
  for (final marketId in marketIds) {
    perMarketTotals[marketId] = const BasketMarketTotal(
      total: 0,
      missingKeys: [],
    );
  }

  final perItemChoice = <String, BasketItemChoice>{};
  final missingKeys = <String>[];
  double mixedTotal = 0;

  for (final item in items) {
    final marketPrices = pricesIndex[item.key] ?? {};
    if (marketPrices.isEmpty) {
      missingKeys.add(item.key);
    }

    for (final marketId in marketIds) {
      final price = marketPrices[marketId];
      final current = perMarketTotals[marketId];
      if (current == null) continue;
      if (price == null) {
        perMarketTotals[marketId] = BasketMarketTotal(
          total: current.total,
          missingKeys: [...current.missingKeys, item.key],
        );
      } else {
        perMarketTotals[marketId] = BasketMarketTotal(
          total: current.total + price * item.quantity,
          missingKeys: current.missingKeys,
        );
      }
    }

    if (marketPrices.isNotEmpty) {
      final cheapestEntry = marketPrices.entries.reduce(
        (a, b) => a.value <= b.value ? a : b,
      );
      final lineTotal = cheapestEntry.value * item.quantity;
      perItemChoice[item.key] = BasketItemChoice(
        marketId: cheapestEntry.key,
        marketName: marketNames[cheapestEntry.key] ?? cheapestEntry.key,
        unitPrice: cheapestEntry.value,
        quantity: item.quantity,
        lineTotal: lineTotal,
      );
      mixedTotal += lineTotal;
    }
  }

  BasketBestSingleMarketResult? bestSingleMarket;
  for (final entry in perMarketTotals.entries) {
    if (entry.value.missingKeys.isNotEmpty) continue;
    if (bestSingleMarket == null || entry.value.total < bestSingleMarket.total) {
      bestSingleMarket = BasketBestSingleMarketResult(
        marketId: entry.key,
        marketName: marketNames[entry.key] ?? entry.key,
        total: entry.value.total,
      );
    }
  }

  return BasketPricingSummary(
    bestSingleMarket: bestSingleMarket,
    mixedResult: BasketMixedResult(
      total: mixedTotal,
      perItemChoice: perItemChoice,
      missingKeys: missingKeys,
    ),
    perMarketTotals: perMarketTotals,
  );
}
