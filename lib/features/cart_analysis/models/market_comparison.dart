import 'package:cloud_firestore/cloud_firestore.dart';

class ProductPriceDiff {
  const ProductPriceDiff({
    required this.productId,
    required this.productName,
    required this.marketPrice,
    required this.cheapestPrice,
  });

  final String productId;
  final String productName;
  final double marketPrice;
  final double cheapestPrice;

  double get delta => marketPrice - cheapestPrice;
  bool get isHigher => delta > 0;
}

class MarketComparison {
  const MarketComparison({
    required this.marketId,
    required this.marketName,
    required this.distanceKm,
    required this.total,
    required this.hasAllProducts,
    required this.productDiffs,
  });

  final String marketId;
  final String marketName;
  final double distanceKm;
  final double total;
  final bool hasAllProducts;
  final List<ProductPriceDiff> productDiffs;

  factory MarketComparison.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return MarketComparison(
      marketId: doc.id,
      marketName: (data['name'] as String?) ?? 'Market',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 0,
      total: (data['total'] as num?)?.toDouble() ?? 0,
      hasAllProducts: (data['hasAllProducts'] as bool?) ?? true,
      productDiffs: const [],
    );
  }

  MarketComparison copyWith({
    String? marketId,
    String? marketName,
    double? distanceKm,
    double? total,
    bool? hasAllProducts,
    List<ProductPriceDiff>? productDiffs,
  }) {
    return MarketComparison(
      marketId: marketId ?? this.marketId,
      marketName: marketName ?? this.marketName,
      distanceKm: distanceKm ?? this.distanceKm,
      total: total ?? this.total,
      hasAllProducts: hasAllProducts ?? this.hasAllProducts,
      productDiffs: productDiffs ?? this.productDiffs,
    );
  }
}

class MarketComparisonBundle {
  const MarketComparisonBundle({
    required this.winner,
    required this.alternatives,
    required this.savingAmount,
  });

  final MarketComparison? winner;
  final List<MarketComparison> alternatives;
  final double savingAmount;
}
