import 'package:cloud_firestore/cloud_firestore.dart';
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

  Map<String, dynamic> toMap() => {
        'store': store,
        'price': price,
        'date': Timestamp.fromDate(date),
        'reportedBy': reportedBy,
      };

  factory PriceEntry.fromMap(Map<String, dynamic> m) {
    final d = m['date'];
    return PriceEntry(
      store: (m['store'] ?? '') as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      date: d is Timestamp ? d.toDate() : DateTime.now(),
      reportedBy: (m['reportedBy'] ?? 'Sen') as String,
    );
  }
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
      priceHistory.isEmpty ? null : _sorted().last.price;

  double? get previousPrice {
    final s = _sorted();
    if (s.length < 2) return null;
    return s[s.length - 2].price;
  }

  double? get priceChangePct {
    final l = latestPrice;
    final p = previousPrice;
    if (l == null || p == null || p == 0) return null;
    return ((l - p) / p) * 100.0;
  }

  List<PriceEntry> _sorted() {
    final s = [...priceHistory];
    s.sort((a, b) => a.date.compareTo(b.date));
    return s;
  }

  double? get lowestPrice => priceHistory.isEmpty
      ? null
      : priceHistory.map((e) => e.price).reduce((a, b) => a < b ? a : b);

  String? get cheapestStore {
    if (priceHistory.isEmpty) return null;
    final p = priceHistory.reduce((a, b) => a.price < b.price ? a : b);
    return p.store;
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'brand': brand,
        'category': category,
        'emoji': emoji,
        'unit': unit,
        'priceHistory': priceHistory.map((e) => e.toMap()).toList(),
      };

  factory Product.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return Product(
      id: d.id,
      name: (m['name'] ?? '') as String,
      brand: (m['brand'] ?? '') as String,
      category: (m['category'] ?? 'Tümü') as String,
      emoji: (m['emoji'] ?? '🛒') as String,
      unit: (m['unit'] ?? '') as String,
      priceHistory: ((m['priceHistory'] as List?) ?? [])
          .map((e) => PriceEntry.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class CartItem {
  final Product product;
  int quantity;
  CartItem({required this.product, this.quantity = 1});
}

class AppBanner {
  final String id;
  final String title;
  final String subtitle;
  final String actionLabel;
  final int order;
  const AppBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.order,
  });
  factory AppBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    return AppBanner(
      id: d.id,
      title: (m['title'] ?? '') as String,
      subtitle: (m['subtitle'] ?? '') as String,
      actionLabel: (m['actionLabel'] ?? 'Keşfet') as String,
      order: (m['order'] as num?)?.toInt() ?? 0,
    );
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final read = m['readAt'];
    return AppNotification(
      id: d.id,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      readAt: read is Timestamp ? read.toDate() : null,
    );
  }
}

class ProductAlert {
  final String productId;
  final double targetPrice;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductAlert({
    required this.productId,
    required this.targetPrice,
    required this.createdAt,
    this.updatedAt,
  });

  factory ProductAlert.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? <String, dynamic>{};
    final created = m['createdAt'];
    final updated = m['updatedAt'];
    return ProductAlert(
      productId: d.id,
      targetPrice: (m['targetPrice'] as num?)?.toDouble() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      updatedAt: updated is Timestamp ? updated.toDate() : null,
    );
  }
}
