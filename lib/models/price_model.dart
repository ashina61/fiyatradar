import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String productId;
  final String? barcode;
  final String userId;
  final double price;
  final String branchStoreId;
  final String? chainId;
  final String currency;
  final DateTime reportedAt;
  final String? photoUrl;
  final int upVotes;
  final int downVotes;
  final double score;

  // Backward compatible UI fields
  final String? productName;
  final String? userName;
  final String? storeName;
  final String? storeLocation;
  final GeoPoint? geoPoint;
  final List<String> images;
  final int verifiedCount;
  final int unverifiedCount;
  final bool isApproved;
  final bool isPending;

  PriceModel({
    required this.id,
    required this.productId,
    this.barcode,
    required this.userId,
    required this.price,
    required this.branchStoreId,
    this.chainId,
    this.currency = 'TRY',
    required this.reportedAt,
    this.photoUrl,
    this.upVotes = 0,
    this.downVotes = 0,
    this.score = 0,
    this.productName,
    this.userName,
    this.storeName,
    this.storeLocation,
    this.geoPoint,
    this.images = const [],
    this.verifiedCount = 0,
    this.unverifiedCount = 0,
    this.isApproved = false,
    this.isPending = true,
  });

  DateTime get createdAt => reportedAt;
  String? get productBarcode => barcode;

  double get verificationRate {
    final total = verifiedCount + unverifiedCount;
    if (total == 0) return 0;
    return (verifiedCount / total) * 100;
  }

  bool get hasPhotos => photoUrl != null || images.isNotEmpty;
  int get photoBonus => hasPhotos ? 2 : 1;
  double get netScore => (upVotes - downVotes) * photoBonus.toDouble();
  bool get isTrustedPrice => netScore > 10;
  bool get shouldAutoHide => netScore < -5;

  factory PriceModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final photo = data['photoUrl'] as String?;
    final imageList = List<String>.from(data['images'] ?? []);

    return PriceModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      barcode: data['barcode'] ?? data['productBarcode'],
      userId: data['userId'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      branchStoreId: data['branchStoreId'] ?? data['storeId'] ?? '',
      chainId: data['chainId'],
      currency: data['currency'] ?? 'TRY',
      reportedAt:
          (data['reportedAt'] as Timestamp?)?.toDate() ??
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      photoUrl: photo ?? (imageList.isNotEmpty ? imageList.first : null),
      upVotes: data['upVotes'] ?? 0,
      downVotes: data['downVotes'] ?? 0,
      score: (data['score'] as num?)?.toDouble() ?? 0,
      productName: data['productName'] ?? data['name'],
      userName: data['userName'],
      storeName: data['storeName'],
      storeLocation: data['storeLocation'],
      geoPoint: data['geoPoint'] as GeoPoint?,
      images: imageList,
      verifiedCount: data['verifiedCount'] ?? 0,
      unverifiedCount: data['unverifiedCount'] ?? 0,
      isApproved: data['isApproved'] ?? false,
      isPending: data['isPending'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    final mergedImages = [
      if (photoUrl != null && photoUrl!.isNotEmpty) photoUrl!,
      ...images,
    ].toSet().toList();

    return {
      'productId': productId,
      'barcode': barcode,
      'userId': userId,
      'price': price,
      'branchStoreId': branchStoreId,
      'chainId': chainId,
      // Legacy field kept for backward-compatibility with existing queries.
      'storeId': branchStoreId,
      'currency': currency,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'photoUrl': photoUrl,
      'upVotes': upVotes,
      'downVotes': downVotes,
      'score': score,
      // backward-compatible extras
      'productName': productName,
      'userName': userName,
      'storeName': storeName,
      'storeLocation': storeLocation,
      'geoPoint': geoPoint,
      'images': mergedImages,
      'createdAt': Timestamp.fromDate(reportedAt),
      'verifiedCount': verifiedCount,
      'unverifiedCount': unverifiedCount,
      'isApproved': isApproved,
      'isPending': isPending,
    };
  }

  PriceModel copyWith({
    String? id,
    String? productId,
    String? barcode,
    String? userId,
    double? price,
    String? branchStoreId,
    String? chainId,
    String? currency,
    DateTime? reportedAt,
    String? photoUrl,
    int? upVotes,
    int? downVotes,
    double? score,
    String? productName,
    String? userName,
    String? storeName,
    String? storeLocation,
    GeoPoint? geoPoint,
    List<String>? images,
    int? verifiedCount,
    int? unverifiedCount,
    bool? isApproved,
    bool? isPending,
  }) {
    return PriceModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      userId: userId ?? this.userId,
      price: price ?? this.price,
      branchStoreId: branchStoreId ?? this.branchStoreId,
      chainId: chainId ?? this.chainId,
      currency: currency ?? this.currency,
      reportedAt: reportedAt ?? this.reportedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      upVotes: upVotes ?? this.upVotes,
      downVotes: downVotes ?? this.downVotes,
      score: score ?? this.score,
      productName: productName ?? this.productName,
      userName: userName ?? this.userName,
      storeName: storeName ?? this.storeName,
      storeLocation: storeLocation ?? this.storeLocation,
      geoPoint: geoPoint ?? this.geoPoint,
      images: images ?? this.images,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      unverifiedCount: unverifiedCount ?? this.unverifiedCount,
      isApproved: isApproved ?? this.isApproved,
      isPending: isPending ?? this.isPending,
    );
  }

  /// Backward-compatible alias for older usages.
  String get storeId => branchStoreId;
}
