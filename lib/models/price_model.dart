import 'package:cloud_firestore/cloud_firestore.dart';

class PriceModel {
  final String id;
  final String productId;
  final String? barcode;
  final String userId;
  final String? createdByUid;
  final double price;
  final String branchStoreId;
  final String? chainId;
  final String priceSourceType;
  final String status;
  final String currency;
  final DateTime reportedAt;
  final String? photoUrl;
  final int upVotes;
  final int downVotes;
  final double score;
  final Map<String, String> userVotes;

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
  final String? dedupeKey;
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
    this.createdByUid,
    required this.price,
    required this.branchStoreId,
    this.chainId,
    this.priceSourceType = 'branch',
    this.status = 'active',
    this.currency = 'TRY',
    required this.reportedAt,
    this.photoUrl,
    this.upVotes = 0,
    this.downVotes = 0,
    this.score = 0,
    this.userVotes = const {},
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
    this.verificationStatus = 'unverified',
    this.userAvatarUrl,
    this.trustLabel = 'Yeni',
    this.trustPercent = 30,
    this.uniqueKey,
    this.dedupeKey,
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
  bool get isActive => status == 'active';

  double get verificationRate {
    final total = upVotes + downVotes;
    if (total == 0) return 0;
    return (upVotes / total) * 100;
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

    normalized = normalized.replaceAll('₺', '').replaceAll('TL', '').replaceAll(RegExp(r'\s+'), '');

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
    final verification = Map<String, dynamic>.from(data['verification'] as Map? ?? const {});

    final up = (data['verifyUpCount'] as num?)?.toInt() ??
        (verification['upCount'] as num?)?.toInt() ??
        (data['upVotes'] as num?)?.toInt() ??
        (data['verifiedCount'] as num?)?.toInt() ??
        0;
    final down = (data['verifyDownCount'] as num?)?.toInt() ??
        (verification['downCount'] as num?)?.toInt() ??
        (data['downVotes'] as num?)?.toInt() ??
        (data['unverifiedCount'] as num?)?.toInt() ??
        0;

    return PriceModel(
      id: doc.id,
      productId: (data['productId'] ?? '').toString(),
      barcode: (data['barcode'] ?? data['productBarcode']) as String?,
      userId: (data['userId'] ?? data['createdByUid'] ?? '').toString(),
      createdByUid: (data['createdByUid'] ?? data['userId']) as String?,
      price: _parsePriceValue(data['price']),
      branchStoreId: (data['branchStoreId'] ?? data['branchId'] ?? data['storeId'] ?? '').toString(),
      chainId: data['chainId'] as String?,
      priceSourceType: (data['priceSourceType'] ?? 'branch').toString(),
      status: (data['status'] ?? 'active').toString(),
      currency: (data['currency'] ?? 'TRY').toString(),
      reportedAt: (data['reportedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: photo ?? (imageList.isNotEmpty ? imageList.first : null),
      upVotes: up,
      downVotes: down,
      score: (data['verifyScore'] as num?)?.toDouble() ?? (verification['score'] as num?)?.toDouble() ?? (data['score'] as num?)?.toDouble() ?? (up - down).toDouble(),
      userVotes: Map<String, String>.from(verification['userVotes'] as Map? ?? const {}),
      productName: data['productName'] as String?,
      userName: data['userName'] as String?,
      storeName: data['storeName'] as String?,
      storeLocation: data['storeLocation'] as String?,
      geoPoint: data['geoPoint'] as GeoPoint?,
      images: imageList,
      verifiedCount: (data['verifiedCount'] as num?)?.toInt() ?? up,
      unverifiedCount: (data['unverifiedCount'] as num?)?.toInt() ?? down,
      isApproved: data['isApproved'] == true,
      isPending: data['isPending'] != false,
      verificationStatus: (data['verificationStatus'] ?? 'unverified').toString(),
      userAvatarUrl: data['userAvatarUrl'] as String?,
      trustLabel: (data['trustLabel'] ?? 'Yeni').toString(),
      trustPercent: (data['trustPercent'] as num?)?.toInt() ?? 30,
      uniqueKey: data['uniqueKey'] as String?,
      dedupeKey: (data['dedupeKey'] as String?) ?? _buildDedupeKeyFallback(data),
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
    final mergedImages = [if (photoUrl != null && photoUrl!.isNotEmpty) photoUrl!, ...images].toSet().toList();

    return {
      'productId': productId,
      'barcode': barcode,
      'userId': userId,
      'createdByUid': createdByUid ?? userId,
      'price': price,
      'branchStoreId': branchStoreId,
      'branchId': branchStoreId,
      'priceSourceType': 'branch',
      'status': status,
      'chainId': chainId,
      'storeId': branchStoreId,
      'currency': currency,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'photoUrl': photoUrl,
      'upVotes': upVotes,
      'downVotes': downVotes,
      'score': score,
      'verification': {
        'upCount': upVotes,
        'downCount': downVotes,
        'score': upVotes - downVotes,
        'userVotes': userVotes,
        'updatedAt': FieldValue.serverTimestamp(),
      },
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
      'dedupeKey': dedupeKey,
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
    String? createdByUid,
    double? price,
    String? branchStoreId,
    String? chainId,
    String? priceSourceType,
    String? status,
    String? currency,
    DateTime? reportedAt,
    String? photoUrl,
    int? upVotes,
    int? downVotes,
    double? score,
    Map<String, String>? userVotes,
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
    String? dedupeKey,
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
      createdByUid: createdByUid ?? this.createdByUid,
      price: price ?? this.price,
      branchStoreId: branchStoreId ?? this.branchStoreId,
      chainId: chainId ?? this.chainId,
      priceSourceType: priceSourceType ?? this.priceSourceType,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      reportedAt: reportedAt ?? this.reportedAt,
      photoUrl: photoUrl ?? this.photoUrl,
      upVotes: upVotes ?? this.upVotes,
      downVotes: downVotes ?? this.downVotes,
      score: score ?? this.score,
      userVotes: userVotes ?? this.userVotes,
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
      dedupeKey: dedupeKey ?? this.dedupeKey,
      addedByDisplayName: addedByDisplayName ?? this.addedByDisplayName,
      addedByTrustScoreSnapshot: addedByTrustScoreSnapshot ?? this.addedByTrustScoreSnapshot,
      addedByLevelSnapshot: addedByLevelSnapshot ?? this.addedByLevelSnapshot,
      addedByVerifiedBadge: addedByVerifiedBadge ?? this.addedByVerifiedBadge,
      createdByTrustScoreSnapshot: createdByTrustScoreSnapshot ?? this.createdByTrustScoreSnapshot,
      createdByBadgeSnapshot: createdByBadgeSnapshot ?? this.createdByBadgeSnapshot,
      createdByVerifiedSnapshot: createdByVerifiedSnapshot ?? this.createdByVerifiedSnapshot,
    );
  }

  static String _localDayKey(DateTime dateTime) {
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}$month$day';
  }

  static String? _buildDedupeKeyFallback(Map<String, dynamic> data) {
    final productId = (data['productId'] ?? '').toString().trim();
    final branchStoreId =
        (data['branchStoreId'] ?? data['branchId'] ?? data['storeId'] ?? '').toString().trim();
    final createdAt =
        (data['reportedAt'] as Timestamp?)?.toDate() ?? (data['createdAt'] as Timestamp?)?.toDate();

    if (productId.isEmpty || branchStoreId.isEmpty || createdAt == null) {
      return null;
    }

    return '$productId|$branchStoreId|${_parsePriceValue(data['price']).toStringAsFixed(2)}|${_localDayKey(createdAt)}';
  }

  String get storeId => branchStoreId;
}
