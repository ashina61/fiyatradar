import 'package:cloud_firestore/cloud_firestore.dart';

class BasketItemModel {
  final String productId;
  final int quantity;
  final DateTime? addedAt;

  BasketItemModel({
    required this.productId,
    required this.quantity,
    this.addedAt,
  });

  factory BasketItemModel.fromFirestore(Map<String, dynamic> data) {
    return BasketItemModel(
      productId: data['productId'] ?? '',
      quantity: data['quantity'] ?? 1,
      addedAt: (data['addedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'quantity': quantity,
      'addedAt': addedAt != null ? Timestamp.fromDate(addedAt!) : null,
    };
  }
}
