import 'package:cloud_firestore/cloud_firestore.dart';

class ProductSuggestionModel {
  final String id;
  final String name;
  final String barcode;
  final String category;
  final String brand;
  final String imageUrl;
  final String userId;
  final String status;
  final DateTime createdAt;

  const ProductSuggestionModel({
    required this.id,
    required this.name,
    required this.barcode,
    required this.category,
    required this.brand,
    required this.imageUrl,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  factory ProductSuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductSuggestionModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      barcode: (data['barcode'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      brand: (data['brand'] ?? '').toString(),
      imageUrl: ((data['imageUrl'] ?? data['photoUrl']) ?? '').toString(),
      userId: (data['userId'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
