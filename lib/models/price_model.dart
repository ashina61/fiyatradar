import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String productId;
  final String? barcode;
  final String userId;
  final double price;
  final String branchStoreId;
  final String? chainId;
  final String priceSourceType;
  final String? neighborhoodMarketId;
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
  final String verificationStatus;
  final String? userAvatarUrl;
  final String trustLabel;
  final int trustPercent;
  final String? uniqueKey;
  final String? addedByDisplayName;
  final double addedByTrustScoreSnapshot;
  final String? addedByLevelSnapshot;
  final bool addedByVerifiedBadge;
  final double createdByTrustScoreSnapshot;
  final String? createdByBadgeSnapshot;
  final bool createdByVerifiedSnapshot;

  PriceModel({
    required this.id,
    required this.productId,
    this.barcode,
    required this.userId,
    required this.price,
    required this.branchStoreId,
    this.chainId,
    this.priceSourceType = 'branch',
    this.neighborhoodMarketId,
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
    this.verificationStatus = 'pending',
    this.userAvatarUrl,
    this.trustLabel = 'Yeni',
    this.trustPercent = 30,
    this.uniqueKey,
    this.addedByDisplayName,
    this.addedByTrustScoreSnapshot = 0,
    this.addedByLevelSnapshot,
    this.addedByVerifiedBadge = false,
    this.createdByTrustScoreSnapshot = 0,
    this.createdByBadgeSnapshot,
    this.createdByVerifiedSnapshot = false,
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

  static double _parsePriceValue(dynamic rawValue) {
    if (rawValue is num) return rawValue.toDouble();
    if (rawValue is! String) return 0;

    var normalized = rawValue.trim();
    if (normalized.isEmpty) return 0;

    normalized = normalized
        .replaceAll('₺', '')
        .replaceAll('TL', '')
        .replaceAll(RegExp(r'\s+'), '');

    if (normalized.contains(',') && normalized.contains('.')) {
      final lastComma = normalized.lastIndexOf(',');
      final lastDot = normalized.lastIndexOf('.');
      if (lastComma > lastDot) {
        normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else if (normalized.contains(',')) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(normalized) ?? 0;
  }

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
      price: _parsePriceValue(data['price']),
      branchStoreId: (data['branchStoreId'] ?? data['branchId'] ?? data['storeId'] ?? '').toString(),
      chainId: data['chainId'],
      priceSourceType: (data['priceSourceType'] ?? 'branch').toString(),
      neighborhoodMarketId: data['neighborhoodMarketId'] as String?,
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
      verificationStatus: (data['verificationStatus'] ?? 'pending').toString(),
      userAvatarUrl: data['userAvatarUrl'] as String?,
      trustLabel: (data['trustLabel'] ?? 'Yeni').toString(),
      trustPercent: (data['trustPercent'] as num?)?.toInt() ?? 30,
      uniqueKey: data['uniqueKey'] as String?,
      addedByDisplayName: (data['addedByDisplayName'] ?? data['userName']) as String?,
      addedByTrustScoreSnapshot: (data['addedByTrustScoreSnapshot'] as num?)?.toDouble() ?? (data['createdByTrustScoreSnapshot'] as num?)?.toDouble() ?? 0,
      addedByLevelSnapshot: (data['addedByLevelSnapshot'] ?? data['createdByBadgeSnapshot']) as String?,
      addedByVerifiedBadge: data['addedByVerifiedBadge'] == true || data['createdByVerifiedSnapshot'] == true,
      createdByTrustScoreSnapshot: (data['createdByTrustScoreSnapshot'] as num?)?.toDouble() ?? (data['addedByTrustScoreSnapshot'] as num?)?.toDouble() ?? 0,
      createdByBadgeSnapshot: (data['createdByBadgeSnapshot'] ?? data['addedByLevelSnapshot']) as String?,
      createdByVerifiedSnapshot: data['createdByVerifiedSnapshot'] == true || data['addedByVerifiedBadge'] == true,
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
      'branchStoreId': priceSourceType == 'branch' ? branchStoreId : null,
      'branchId': priceSourceType == 'branch' ? branchStoreId : null,
      'neighborhoodMarketId': priceSourceType == 'neighborhood_market' ? neighborhoodMarketId : null,
      'priceSourceType': priceSourceType,
      'chainId': chainId,
      // Legacy field kept for backward-compatibility with existing queries.
      'storeId': priceSourceType == 'branch' ? branchStoreId : null,
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
      'verificationStatus': verificationStatus,
      'userAvatarUrl': userAvatarUrl,
      'trustLabel': trustLabel,
      'trustPercent': trustPercent,
      'uniqueKey': uniqueKey,
      'addedByDisplayName': addedByDisplayName,
      'addedByTrustScoreSnapshot': addedByTrustScoreSnapshot,
      'addedByLevelSnapshot': addedByLevelSnapshot,
      'addedByVerifiedBadge': addedByVerifiedBadge,
      'createdByTrustScoreSnapshot': createdByTrustScoreSnapshot,
      'createdByBadgeSnapshot': createdByBadgeSnapshot,
      'createdByVerifiedSnapshot': createdByVerifiedSnapshot,
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
    String? priceSourceType,
    String? neighborhoodMarketId,
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
    String? verificationStatus,
    String? userAvatarUrl,
    String? trustLabel,
    int? trustPercent,
    String? uniqueKey,
    String? addedByDisplayName,
    double? addedByTrustScoreSnapshot,
    String? addedByLevelSnapshot,
    bool? addedByVerifiedBadge,
    double? createdByTrustScoreSnapshot,
    String? createdByBadgeSnapshot,
    bool? createdByVerifiedSnapshot,
  }) {
    return PriceModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      barcode: barcode ?? this.barcode,
      userId: userId ?? this.userId,
      price: price ?? this.price,
      branchStoreId: branchStoreId ?? this.branchStoreId,
      chainId: chainId ?? this.chainId,
      priceSourceType: priceSourceType ?? this.priceSourceType,
      neighborhoodMarketId: neighborhoodMarketId ?? this.neighborhoodMarketId,
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
      verificationStatus: verificationStatus ?? this.verificationStatus,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      trustLabel: trustLabel ?? this.trustLabel,
      trustPercent: trustPercent ?? this.trustPercent,
      uniqueKey: uniqueKey ?? this.uniqueKey,
      addedByDisplayName: addedByDisplayName ?? this.addedByDisplayName,
      addedByTrustScoreSnapshot: addedByTrustScoreSnapshot ?? this.addedByTrustScoreSnapshot,
      addedByLevelSnapshot: addedByLevelSnapshot ?? this.addedByLevelSnapshot,
      addedByVerifiedBadge: addedByVerifiedBadge ?? this.addedByVerifiedBadge,
      createdByTrustScoreSnapshot: createdByTrustScoreSnapshot ?? this.createdByTrustScoreSnapshot,
      createdByBadgeSnapshot: createdByBadgeSnapshot ?? this.createdByBadgeSnapshot,
      createdByVerifiedSnapshot: createdByVerifiedSnapshot ?? this.createdByVerifiedSnapshot,
    );
  }

  /// Backward-compatible alias for older usages.
  String get storeId => branchStoreId;
}
