import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'market_comparison.dart';

final comparisonProvider = Provider<List<MarketComparison>>((ref) {
  return const [
    MarketComparison(
      marketName: 'A-101',
      distanceKm: 0.2,
      totalPrice: 87,
      rank: 1,
      hasMissing: false,
      missingCount: 0,
      details: [
        ProductComparisonDetail(productName: 'Nutella 400g', price: 32, diff: 0),
        ProductComparisonDetail(productName: "15'li Yumurta", price: 15, diff: 0),
        ProductComparisonDetail(productName: 'Sarıyer Kola', price: 40, diff: 0),
      ],
    ),
    MarketComparison(
      marketName: 'BİM Market',
      distanceKm: 0.5,
      totalPrice: 92,
      rank: 2,
      hasMissing: false,
      missingCount: 0,
      details: [
        ProductComparisonDetail(productName: 'Nutella 400g', price: 36, diff: 4),
        ProductComparisonDetail(productName: "15'li Yumurta", price: 16, diff: 1),
        ProductComparisonDetail(productName: 'Sarıyer Kola', price: 40, diff: 0),
      ],
    ),
    MarketComparison(
      marketName: 'Migros',
      distanceKm: 1.2,
      totalPrice: 105,
      rank: 3,
      hasMissing: false,
      missingCount: 0,
      details: [
        ProductComparisonDetail(productName: 'Nutella 400g', price: 44, diff: 12),
        ProductComparisonDetail(productName: "15'li Yumurta", price: 21, diff: 6),
        ProductComparisonDetail(productName: 'Sarıyer Kola', price: 40, diff: 0),
      ],
    ),
    MarketComparison(
      marketName: 'ŞOK Market',
      distanceKm: 0.8,
      totalPrice: 55,
      rank: 4,
      hasMissing: true,
      missingCount: 1,
      details: [
        ProductComparisonDetail(
          productName: 'Nutella 400g',
          price: 0,
          diff: 0,
          missing: true,
        ),
      ],
    ),
  ];
});

final expandedMarketProvider = StateProvider<String?>((ref) => null);
