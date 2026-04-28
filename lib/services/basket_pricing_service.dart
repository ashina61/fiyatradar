import '../models/price_reporting.dart';

class BasketLineResolution {
  final String productId;
  final int quantity;
  final String chainName;
  final double unitPrice;
  final String usedPriceSource;
  final String sourceTypeLabel;
  final String confidence;

  const BasketLineResolution({
    required this.productId,
    required this.quantity,
    required this.chainName,
    required this.unitPrice,
    required this.usedPriceSource,
    required this.sourceTypeLabel,
    required this.confidence,
  });

  double get lineTotal => unitPrice * quantity;
}

class BasketStoreEstimate {
  final String chainName;
  final double estimatedTotal;
  final int foundItemCount;
  final int missingItemCount;
  final String confidence;
  final String usedPriceSource;
  final List<String> missingProductIds;

  const BasketStoreEstimate({
    required this.chainName,
    required this.estimatedTotal,
    required this.foundItemCount,
    required this.missingItemCount,
    required this.confidence,
    required this.usedPriceSource,
    required this.missingProductIds,
  });
}

class BasketMixedEstimate {
  final double estimatedTotal;
  final int marketCount;
  final List<BasketLineResolution> lines;

  const BasketMixedEstimate({
    required this.estimatedTotal,
    required this.marketCount,
    required this.lines,
  });
}

class BasketSmartSuggestion {
  final BasketStoreEstimate bestSingleMarket;
  final BasketMixedEstimate cheapestMixed;
  final String message;

  const BasketSmartSuggestion({
    required this.bestSingleMarket,
    required this.cheapestMixed,
    required this.message,
  });
}

class BasketPricingResult {
  final List<BasketStoreEstimate> singleMarketEstimates;
  final BasketMixedEstimate? cheapestMixed;
  final BasketSmartSuggestion? smartSuggestion;

  const BasketPricingResult({
    required this.singleMarketEstimates,
    required this.cheapestMixed,
    required this.smartSuggestion,
  });
}

class BasketPricingService {
  const BasketPricingService();

  BasketPricingResult calculate({
    required List<({String productId, int quantity})> items,
    required List<PriceGroupModel> groups,
  }) {
    final singles = calculateSingleStoreTotals(items: items, groups: groups);
    final mixed = calculateCheapestMixed(items: items, groups: groups);
    final smart = buildSmartSuggestion(singles: singles, mixed: mixed);
    return BasketPricingResult(
      singleMarketEstimates: singles,
      cheapestMixed: mixed,
      smartSuggestion: smart,
    );
  }

  List<BasketStoreEstimate> calculateSingleStoreTotals({
    required List<({String productId, int quantity})> items,
    required List<PriceGroupModel> groups,
  }) {
    final byChain = <String, List<PriceGroupModel>>{};
    for (final g in groups) {
      if (g.chainName.trim().isEmpty) continue;
      byChain.putIfAbsent(g.chainName, () => <PriceGroupModel>[]).add(g);
    }

    final out = <BasketStoreEstimate>[];
    for (final chainEntry in byChain.entries) {
      final chain = chainEntry.key;
      final groupByProduct = <String, PriceGroupModel>{
        for (final g in chainEntry.value) g.productId: g,
      };
      var total = 0.0;
      var found = 0;
      final missing = <String>[];
      final sources = <String>[];
      final confidenceScores = <int>[];
      for (final item in items) {
        final g = groupByProduct[item.productId];
        final unit = g?.preferredPrice;
        if (unit == null) {
          missing.add(item.productId);
          continue;
        }
        total += (unit * item.quantity);
        found += 1;
        sources.add(g!.preferredPriceSource);
        confidenceScores.add(_confidenceScore(g.confidence));
      }

      out.add(
        BasketStoreEstimate(
          chainName: chain,
          estimatedTotal: total,
          foundItemCount: found,
          missingItemCount: items.length - found,
          confidence: _confidenceLabel(confidenceScores),
          usedPriceSource: _dominant(sources),
          missingProductIds: missing,
        ),
      );
    }

    out.sort((a, b) {
      final coverageA = a.foundItemCount / (a.foundItemCount + a.missingItemCount + 0.0001);
      final coverageB = b.foundItemCount / (b.foundItemCount + b.missingItemCount + 0.0001);
      final byCoverage = coverageB.compareTo(coverageA);
      if (byCoverage != 0) return byCoverage;
      return a.estimatedTotal.compareTo(b.estimatedTotal);
    });
    return out;
  }

  BasketMixedEstimate? calculateCheapestMixed({
    required List<({String productId, int quantity})> items,
    required List<PriceGroupModel> groups,
  }) {
    final lines = <BasketLineResolution>[];
    for (final item in items) {
      final options = groups
          .where((g) => g.productId == item.productId && g.preferredPrice != null)
          .toList()
        ..sort((a, b) => a.preferredPrice!.compareTo(b.preferredPrice!));
      if (options.isEmpty) continue;
      final best = options.first;
      lines.add(
        BasketLineResolution(
          productId: item.productId,
          quantity: item.quantity,
          chainName: best.chainName,
          unitPrice: best.preferredPrice!,
          usedPriceSource: best.preferredPriceSource,
          sourceTypeLabel: priceReportSourceTypeLabelTr(best.sourceType),
          confidence: best.confidence,
        ),
      );
    }
    if (lines.isEmpty) return null;
    final total = lines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final marketCount = lines.map((l) => l.chainName).toSet().length;
    return BasketMixedEstimate(
      estimatedTotal: total,
      marketCount: marketCount,
      lines: lines,
    );
  }

  BasketSmartSuggestion? buildSmartSuggestion({
    required List<BasketStoreEstimate> singles,
    required BasketMixedEstimate? mixed,
  }) {
    if (singles.isEmpty || mixed == null) return null;
    final bestSingle = singles.first;
    final diff = bestSingle.estimatedTotal - mixed.estimatedTotal;
    final message = diff < 60
        ? '${diff.toStringAsFixed(0)} TL fark için ${mixed.marketCount} market gezmek gerekebilir. Tek market daha mantıklı olabilir.'
        : 'Yaklaşık ${diff.toStringAsFixed(0)} TL fark var. Sepeti ${mixed.marketCount} markete bölmek mantıklı görünüyor.';
    return BasketSmartSuggestion(
      bestSingleMarket: bestSingle,
      cheapestMixed: mixed,
      message: message,
    );
  }

  int _confidenceScore(String raw) {
    switch (raw) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  String _confidenceLabel(List<int> scores) {
    if (scores.isEmpty) return 'low';
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg >= 2.5) return 'high';
    if (avg >= 1.7) return 'medium';
    return 'low';
  }

  String _dominant(List<String> values) {
    if (values.isEmpty) return 'none';
    final counts = <String, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}
