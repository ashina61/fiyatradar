import '../../services/cart_comparison_service.dart';

enum CartComparisonStatus { idle, loading, success, empty, error }

class CartMarketResultSummary {
  const CartMarketResultSummary({
    required this.storeId,
    required this.storeName,
    required this.totalPrice,
    required this.missingCount,
    this.distanceKm,
    this.lines = const <CartMarketProductPrice>[],
  });

  final String storeId;
  final String storeName;
  final double totalPrice;
  final double? distanceKm;
  final int missingCount;
  final List<CartMarketProductPrice> lines;

  factory CartMarketResultSummary.fromComparison(CartMarketComparison comparison) {
    return CartMarketResultSummary(
      storeId: comparison.marketId,
      storeName: comparison.marketName,
      totalPrice: comparison.total,
      distanceKm: comparison.distanceKm,
      missingCount: comparison.missingProductIds.length,
      lines: comparison.lines,
    );
  }
}

class CartComparisonState {
  const CartComparisonState({
    required this.status,
    this.bestMarket,
    this.topMarkets = const <CartMarketResultSummary>[],
    this.nearestMarket,
    this.missingProducts = const <String>[],
    this.errorMessage,
    this.emptyReason,
  });

  final CartComparisonStatus status;
  final CartMarketResultSummary? bestMarket;
  final List<CartMarketResultSummary> topMarkets;
  final CartMarketResultSummary? nearestMarket;
  final List<String> missingProducts;
  final String? errorMessage;
  final String? emptyReason;

  const CartComparisonState.idle() : this(status: CartComparisonStatus.idle);

  CartComparisonState copyWith({
    CartComparisonStatus? status,
    CartMarketResultSummary? bestMarket,
    List<CartMarketResultSummary>? topMarkets,
    CartMarketResultSummary? nearestMarket,
    List<String>? missingProducts,
    String? errorMessage,
    String? emptyReason,
    bool clearBestMarket = false,
    bool clearNearestMarket = false,
    bool clearErrorMessage = false,
    bool clearEmptyReason = false,
  }) {
    return CartComparisonState(
      status: status ?? this.status,
      bestMarket: clearBestMarket ? null : (bestMarket ?? this.bestMarket),
      topMarkets: topMarkets ?? this.topMarkets,
      nearestMarket: clearNearestMarket ? null : (nearestMarket ?? this.nearestMarket),
      missingProducts: missingProducts ?? this.missingProducts,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      emptyReason: clearEmptyReason ? null : (emptyReason ?? this.emptyReason),
    );
  }
}
