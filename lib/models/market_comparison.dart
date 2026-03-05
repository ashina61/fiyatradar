class ProductComparisonDetail {
  const ProductComparisonDetail({
    required this.productName,
    required this.price,
    required this.diff,
    this.missing = false,
  });

  final String productName;
  final double price;
  final double diff;
  final bool missing;
}

class MarketComparison {
  const MarketComparison({
    required this.marketName,
    required this.distanceKm,
    required this.totalPrice,
    required this.rank,
    required this.hasMissing,
    required this.missingCount,
    required this.details,
  });

  final String marketName;
  final double distanceKm;
  final double totalPrice;
  final int rank;
  final bool hasMissing;
  final int missingCount;
  final List<ProductComparisonDetail> details;

  double get differenceFromBest => totalPrice - 87;
  bool get isBest => rank == 1;
}
