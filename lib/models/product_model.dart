import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String? mainImage;
  final String? barcode;
  final int viewCount;
  final int priceEntryCount;
  final double? lastPrice;
  final String? lastStore;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    this.mainImage,
    this.barcode,
    this.viewCount = 0,
    this.priceEntryCount = 0,
    this.lastPrice,
    this.lastStore,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isTrending => priceEntryCount >= 10 || viewCount >= 100;

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      mainImage: data['mainImage'],
      barcode: data['barcode'],
      viewCount: data['viewCount'] ?? 0,
      priceEntryCount: data['priceEntryCount'] ?? 0,
      lastPrice: (data['lastPrice'] as num?)?.toDouble(),
      lastStore: data['lastStore'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'mainImage': mainImage,
      'barcode': barcode,
      'viewCount': viewCount,
      'priceEntryCount': priceEntryCount,
      'lastPrice': lastPrice,
      'lastStore': lastStore,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    String? category,
    String? mainImage,
    String? barcode,
    int? viewCount,
    int? priceEntryCount,
    double? lastPrice,
    String? lastStore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      mainImage: mainImage ?? this.mainImage,
      barcode: barcode ?? this.barcode,
      viewCount: viewCount ?? this.viewCount,
      priceEntryCount: priceEntryCount ?? this.priceEntryCount,
      lastPrice: lastPrice ?? this.lastPrice,
      lastStore: lastStore ?? this.lastStore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
