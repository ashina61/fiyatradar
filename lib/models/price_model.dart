import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String productId;
  final String? productName;
  final String? productBarcode;
  final String userId;
  final String? userName;
  final double price;
  final String storeId;
  final String storeName;
  final String? storeLocation;
  final GeoPoint? geoPoint;
  final String currency;
  final List<String> images;
  final DateTime createdAt;
  final int verifiedCount;
  final int unverifiedCount;
  final int upVotes;
  final int downVotes;
  final double score;
  final bool isApproved;
  final bool isPending;

  PriceModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productBarcode,
    required this.userId,
    this.userName,
    required this.price,
    required this.storeId,
    required this.storeName,
    this.storeLocation,
    this.geoPoint,
    this.currency = 'TRY',
    this.images = const [],
    required this.createdAt,
    this.verifiedCount = 0,
    this.unverifiedCount = 0,
    this.upVotes = 0,
    this.downVotes = 0,
    this.score = 0,
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

  /// Net score = upVotes - downVotes (weighted by photoBonus)
  double get netScore => (upVotes - downVotes) * photoBonus.toDouble();

  /// "Guvenilir Fiyat" badge when net score > 10
  bool get isTrustedPrice => netScore > 10;

  /// Auto-hide when score drops below -5
  bool get shouldAutoHide => netScore < -5;

  factory PriceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? data['name'],
      productBarcode: data['productBarcode'] ?? data['barcode'],
      userId: data['userId'] ?? '',
      userName: data['userName'],
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      storeId: data['storeId'] ?? '',
      storeName: data['storeName'] ?? '',
      storeLocation: data['storeLocation'],
      geoPoint: data['geoPoint'] as GeoPoint?,
      currency: data['currency'] ?? 'TRY',
      images: List<String>.from(data['images'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      verifiedCount: data['verifiedCount'] ?? 0,
      unverifiedCount: data['unverifiedCount'] ?? 0,
      upVotes: data['upVotes'] ?? 0,
      downVotes: data['downVotes'] ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      isApproved: data['isApproved'] ?? false,
      isPending: data['isPending'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productName': productName,
      'productBarcode': productBarcode,
      'userId': userId,
      'userName': userName,
      'price': price,
      'storeId': storeId,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'geoPoint': geoPoint,
      'currency': currency,
      'images': images,
      'createdAt': Timestamp.fromDate(createdAt),
      'verifiedCount': verifiedCount,
      'unverifiedCount': unverifiedCount,
      'upVotes': upVotes,
      'downVotes': downVotes,
      'score': score,
      'isApproved': isApproved,
      'isPending': isPending,
    };
  }

  PriceModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productBarcode,
    String? userId,
    String? userName,
    double? price,
    String? storeId,
    String? storeName,
    String? storeLocation,
    GeoPoint? geoPoint,
    String? currency,
    List<String>? images,
    DateTime? createdAt,
    int? verifiedCount,
    int? unverifiedCount,
    int? upVotes,
    int? downVotes,
    double? score,
    bool? isApproved,
    bool? isPending,
  }) {
    return PriceModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productBarcode: productBarcode ?? this.productBarcode,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      price: price ?? this.price,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      storeLocation: storeLocation ?? this.storeLocation,
      geoPoint: geoPoint ?? this.geoPoint,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      createdAt: createdAt ?? this.createdAt,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      unverifiedCount: unverifiedCount ?? this.unverifiedCount,
      upVotes: upVotes ?? this.upVotes,
      downVotes: downVotes ?? this.downVotes,
      score: score ?? this.score,
      isApproved: isApproved ?? this.isApproved,
      isPending: isPending ?? this.isPending,
    );
  }
}
