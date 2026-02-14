import 'package:cloud_firestore/cloud_firestore.dart';

class BasketItemModel {
  final String productId;
  final int quantity;
  final DateTime? addedAt;
  final double? lastKnownPrice;

  BasketItemModel({
    required this.productId,
    required this.quantity,
    this.addedAt,
    this.lastKnownPrice,
  });

  factory BasketItemModel.fromFirestore(Map<String, dynamic> data) {
    return BasketItemModel(
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
      lastKnownPrice: (data['lastKnownPrice'] as num?)?.toDouble(),
    );
  }

  BasketItemModel copyWith({
    String? productId,
    int? quantity,
    DateTime? addedAt,
    double? lastKnownPrice,
    bool clearLastKnownPrice = false,
  }) {
    return BasketItemModel(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      lastKnownPrice: clearLastKnownPrice ? null : (lastKnownPrice ?? this.lastKnownPrice),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'quantity': quantity,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
      'lastKnownPrice': lastKnownPrice,
    };
  }
}
