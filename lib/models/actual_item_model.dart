import 'package:cloud_firestore/cloud_firestore.dart';

class ActualItemModel {
  final String id;
  final String name;
  final double price;
  final double? oldPrice;
  final String imageUrl;
  final String note;
  final bool isActive;
  final DateTime createdAt;

  const ActualItemModel({
    required this.id,
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.imageUrl,
    required this.note,
    required this.isActive,
    required this.createdAt,
  });

  factory ActualItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ActualItemModel(
      id: doc.id,
      name: (data['name'] as String?)?.trim() ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble(),
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      note: (data['note'] as String?)?.trim() ?? '',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'oldPrice': oldPrice,
      'imageUrl': imageUrl,
      'note': note,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
