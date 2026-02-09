import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String productId;
  final String userId;
  final String? userName;
  final double price;
  final String? storeId;
  final String storeName;
  final String? storeLocation;
  final GeoPoint? geoPoint;
  final List<String> images;
  final DateTime createdAt;
  final int verifiedCount;
  final int unverifiedCount;
  final bool isApproved;
  final bool isPending;

  PriceModel({
    required this.id,
    required this.productId,
    required this.userId,
    this.userName,
    required this.price,
    this.storeId,
    required this.storeName,
    this.storeLocation,
    this.geoPoint,
    this.images = const [],
    required this.createdAt,
    this.verifiedCount = 0,
    this.unverifiedCount = 0,
    this.isApproved = false,
    this.isPending = true,
  });

  double get verificationRate {
    final total = verifiedCount + unverifiedCount;
    if (total == 0) return 0;
    return (verifiedCount / total) * 100;
  }

  bool get hasPhotos => images.isNotEmpty;
  int get photoBonus => hasPhotos ? 2 : 1;

  factory PriceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'],
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      storeId: data['storeId'],
      storeName: data['storeName'] ?? '',
      storeLocation: data['storeLocation'],
      geoPoint: data['geoPoint'] as GeoPoint?,
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedCount: data['verifiedCount'] ?? 0,
      unverifiedCount: data['unverifiedCount'] ?? 0,
      isApproved: data['isApproved'] ?? false,
      isPending: data['isPending'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'geoPoint': geoPoint,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedCount': verifiedCount,
      'unverifiedCount': unverifiedCount,
      'isApproved': isApproved,
      'isPending': isPending,
    };
  }

  PriceModel copyWith({
    String? id,
    String? productId,
    String? userId,
    String? userName,
    double? price,
    String? storeId,
    String? storeName,
    String? storeLocation,
    GeoPoint? geoPoint,
    List<String>? images,
    DateTime? createdAt,
    int? verifiedCount,
    int? unverifiedCount,
    bool? isApproved,
    bool? isPending,
  }) {
    return PriceModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      price: price ?? this.price,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeLocation: storeLocation ?? this.storeLocation,
      geoPoint: geoPoint ?? this.geoPoint,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      unverifiedCount: unverifiedCount ?? this.unverifiedCount,
      isApproved: isApproved ?? this.isApproved,
      isPending: isPending ?? this.isPending,
    );
  }
}
