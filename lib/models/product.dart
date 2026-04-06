import 'package:flutter/foundation.dart';

@immutable
class PriceEntry {
  final String store;
  final double price;
  final DateTime date;
  final String reportedBy;

  const PriceEntry({
    required this.store,
    required this.price,
    required this.date,
    this.reportedBy = 'Sen',
  });
}

class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String emoji;
  final String unit;
  final List<PriceEntry> priceHistory;

  Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.emoji,
    required this.unit,
    List<PriceEntry>? priceHistory,
  }) : priceHistory = priceHistory ?? [];

  double? get latestPrice =>
      priceHistory.isEmpty ? null : priceHistory.last.price;

  double? get lowestPrice => priceHistory.isEmpty
      ? null
      : priceHistory.map((e) => e.price).reduce((a, b) => a < b ? a : b);

  String? get cheapestStore {
    if (priceHistory.isEmpty) return null;
    final p = priceHistory.reduce((a, b) => a.price < b.price ? a : b);
    return p.store;
  }
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}
