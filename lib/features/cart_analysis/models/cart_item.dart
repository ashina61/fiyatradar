import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String id;
  final String productId;
  final String productName;
  final String imageUrl;
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  factory CartItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return CartItem(
      id: doc.id,
      productId: (data['productId'] as String?) ?? doc.id,
      productName: (data['productName'] as String?) ?? 'Ürün',
      imageUrl: (data['imageUrl'] as String?) ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    String? imageUrl,
    double? unitPrice,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}
