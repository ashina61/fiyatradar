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
  /// Bu marketteki en eski "preferred" fiyatın yaşı (gün). null → tarih
  /// bilgisi yok / hesap edilemedi. UI bu değeri "freshness" badge'i olarak
  /// gösterip 30 gün üstü için "bayat fiyat" uyarısı yapar.
  final int? oldestPriceAgeDays;

  const BasketStoreEstimate({
    required this.chainName,
    required this.estimatedTotal,
    required this.foundItemCount,
    required this.missingItemCount,
    required this.confidence,
    required this.usedPriceSource,
    required this.missingProductIds,
    required this.oldestPriceAgeDays,
  });

  /// Sepetin yüzde kaçı bu marketten karşılanabiliyor (0.0 .. 1.0).
  double get coverage {
    final total = foundItemCount + missingItemCount;
    return total <= 0 ? 0 : foundItemCount / total;
  }

  bool get isStale =>
      oldestPriceAgeDays != null && oldestPriceAgeDays! > 30;
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
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
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
      int? oldestAgeDays;
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
        if (g.lastReportedAt != null) {
          final ageDays = reference.difference(g.lastReportedAt!).inDays;
          if (oldestAgeDays == null || ageDays > oldestAgeDays) {
            oldestAgeDays = ageDays;
          }
        }
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
          oldestPriceAgeDays: oldestAgeDays,
        ),
      );
    }

    // Sıralama:
    //   1) Coverage en yüksek olan kazanır — eksik ürünlerle "ucuz" görünmek
    //      en sık şikayet olan UX bug'ı.
    //   2) Eşitlikte: bayat olmayan (ageDays<=30) önce.
    //   3) Yine eşitlikte: ucuz olan.
    out.sort((a, b) {
      final byCoverage = b.coverage.compareTo(a.coverage);
      if (byCoverage != 0) return byCoverage;
      final aStale = a.isStale ? 1 : 0;
      final bStale = b.isStale ? 1 : 0;
      if (aStale != bStale) return aStale - bStale;
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
    // Eşik artık sabit ₺60 değil — best-single toplamının %10'u veya
    // ₺80'den hangisi büyükse o. Pahalı sepetlerde küçük yüzde fark için
    // 4 market gezdirmek mantıksız; ucuz sepetlerde ₺60 farkın bile
    // değeri var.
    final threshold = (bestSingle.estimatedTotal * 0.10).clamp(80.0, 250.0);
    // Mixed öneri 3+ markete bölünüyorsa kullanıcı pratikte yapmaz —
    // tek market öner.
    final tooManyStops = mixed.marketCount >= 3;
    final message = (diff < threshold || tooManyStops)
        ? '~₺${diff.toStringAsFixed(0)} fark için ${mixed.marketCount} market gezmek pratik değil. Tek market daha mantıklı.'
        : 'Yaklaşık ₺${diff.toStringAsFixed(0)} fark var. Sepeti ${mixed.marketCount} markete bölmek mantıklı görünüyor.';
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
