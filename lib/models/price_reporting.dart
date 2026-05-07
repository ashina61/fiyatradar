import 'package:cloud_firestore/cloud_firestore.dart';

enum PriceReportSourceType { manualRegional, locationSupported, branchNear }

String priceReportSourceTypeToValue(PriceReportSourceType type) {
  switch (type) {
    case PriceReportSourceType.manualRegional:
      return 'manualRegional';
    case PriceReportSourceType.locationSupported:
      return 'locationSupported';
    case PriceReportSourceType.branchNear:
      return 'branchNear';
  }
}

PriceReportSourceType priceReportSourceTypeFromValue(String? raw) {
  switch (raw) {
    case 'branchNear':
      return PriceReportSourceType.branchNear;
    case 'locationSupported':
      return PriceReportSourceType.locationSupported;
    case 'manualRegional':
    default:
      return PriceReportSourceType.manualRegional;
  }
}

String priceReportSourceTypeLabelTr(PriceReportSourceType type) {
  switch (type) {
    case PriceReportSourceType.manualRegional:
      return 'Bölgesel bildirim';
    case PriceReportSourceType.locationSupported:
      return 'Konum destekli';
    case PriceReportSourceType.branchNear:
      return 'Şube yakınında bildirildi';
  }
}

/// Returns the user-facing confidence band label for a report given its
/// distance to the nearest branch. The bands are intentionally soft so
/// distance never blocks a submission — it only changes the badge.
///
/// 0-30 m   → "Şube yakınında bildirildi"
/// 30-100 m → "Konum uyumlu"
/// >100 m   → "Konum destekli bölgesel fiyat"
/// no GPS   → "Manuel bölgesel fiyat"
String priceReportBandLabelTr({
  required PriceReportSourceType sourceType,
  double? distanceToBranchMeters,
}) {
  if (sourceType == PriceReportSourceType.manualRegional) {
    return 'Manuel bölgesel fiyat';
  }
  if (sourceType == PriceReportSourceType.branchNear) {
    return 'Şube yakınında bildirildi';
  }
  if (distanceToBranchMeters != null) {
    if (distanceToBranchMeters <= 100) return 'Konum uyumlu';
    return 'Konum destekli bölgesel fiyat';
  }
  return 'Konum destekli';
}

String confidenceLabelTr(String raw) {
  switch (raw) {
    case 'high':
      return 'Yüksek';
    case 'medium':
      return 'Orta';
    case 'low':
    default:
      return 'Düşük';
  }
}

class RegionModel {
  final String cityId;
  final String cityName;
  final String districtId;
  final String districtName;

  const RegionModel({
    required this.cityId,
    required this.cityName,
    required this.districtId,
    required this.districtName,
  });
}

class PriceGroupModel {
  final String id;
  final String productId;
  final String productName;
  final String chainId;
  final String chainName;
  final String cityId;
  final String cityName;
  final String districtId;
  final String districtName;
  final double? latestPrice;
  final double? trustedPrice;
  final double? avgPrice;
  final double? minPrice;
  final double? maxPrice;
  final int reportCount;
  final int verifiedCount;
  final int photoReportCount;
  final String confidence;
  final PriceReportSourceType sourceType;
  final DateTime? lastReportedAt;

  const PriceGroupModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.chainId,
    required this.chainName,
    required this.cityId,
    required this.cityName,
    required this.districtId,
    required this.districtName,
    required this.latestPrice,
    required this.trustedPrice,
    required this.avgPrice,
    required this.minPrice,
    required this.maxPrice,
    required this.reportCount,
    required this.verifiedCount,
    required this.photoReportCount,
    required this.confidence,
    required this.sourceType,
    required this.lastReportedAt,
  });

  factory PriceGroupModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? <String, dynamic>{};
    final ts = m['lastReportedAt'];
    return PriceGroupModel(
      id: doc.id,
      productId: (m['productId'] ?? '') as String,
      productName: (m['productName'] ?? '') as String,
      chainId: (m['chainId'] ?? '') as String,
      chainName: ((m['chainName'] ?? '') as String).trim().isEmpty
          ? ((m['marketName'] ?? '') as String)
          : (m['chainName'] as String),
      cityId: (m['cityId'] ?? '') as String,
      cityName: (m['cityName'] ?? '') as String,
      districtId: (m['districtId'] ?? '') as String,
      districtName: (m['districtName'] ?? '') as String,
      latestPrice: (m['latestPrice'] as num?)?.toDouble(),
      trustedPrice: (m['trustedPrice'] as num?)?.toDouble(),
      avgPrice: (m['avgPrice'] as num?)?.toDouble(),
      minPrice: (m['minPrice'] as num?)?.toDouble(),
      maxPrice: (m['maxPrice'] as num?)?.toDouble(),
      reportCount: (m['reportCount'] as num?)?.toInt() ?? 0,
      verifiedCount: (m['verifiedCount'] as num?)?.toInt() ?? 0,
      photoReportCount: (m['photoReportCount'] as num?)?.toInt() ?? 0,
      confidence: (m['confidence'] ?? 'low') as String,
      sourceType: priceReportSourceTypeFromValue(m['sourceType'] as String?),
      lastReportedAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  String get displayTitle => '$chainName · $districtName / $cityName';

  double? get preferredPrice => trustedPrice ?? latestPrice ?? avgPrice ?? minPrice;

  String get preferredPriceSource {
    if (trustedPrice != null) return 'trustedPrice';
    if (latestPrice != null) return 'latestPrice';
    if (avgPrice != null) return 'avgPrice';
    if (minPrice != null) return 'minPrice';
    return 'none';
  }

  bool get hasPhotoEvidence => photoReportCount > 0;
}

/// Bölge katkıcısı sıralaması için lightweight view-model.
/// `priceReports` üzerinden son 30 günü tarayıp kullanıcı bazında
/// aggregate çıkarır. Sıralama UI tarafında yapılır; bu sınıf tek
/// kullanıcının skoru.
class RegionalContributorScore {
  final String userId;
  final String userDisplayName;
  final int reportCount;
  final int photoCount;
  final DateTime? lastReportedAt;

  const RegionalContributorScore({
    required this.userId,
    required this.userDisplayName,
    required this.reportCount,
    required this.photoCount,
    required this.lastReportedAt,
  });

  /// Sıralama skoru: rapor sayısı + fotoğraf bonusu (her foto +0.5).
  /// Pure-numeric, leaderboard sıralaması için.
  double get score => reportCount + (photoCount * 0.5);
}

/// Profil "Katkılarım" listesi için yalın view-model. `priceReports`
/// koleksiyonunun bir doc'undan beslenir — legacy `priceHistory` array'ine
/// bağımlı değildir, yani mirror kalksa bile çalışır.
class MyPriceContribution {
  final String id;
  final String productId;
  final String productName;
  final String chainName;
  final String cityName;
  final String districtName;
  final double price;
  final String? photoUrl;
  final PriceReportSourceType sourceType;
  final DateTime? createdAt;

  const MyPriceContribution({
    required this.id,
    required this.productId,
    required this.productName,
    required this.chainName,
    required this.cityName,
    required this.districtName,
    required this.price,
    required this.photoUrl,
    required this.sourceType,
    required this.createdAt,
  });

  factory MyPriceContribution.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? <String, dynamic>{};
    final ts = m['createdAt'];
    return MyPriceContribution(
      id: doc.id,
      productId: (m['productId'] ?? '') as String,
      productName: (m['productName'] ?? '') as String,
      chainName: (m['chainName'] ?? '') as String,
      cityName: (m['cityName'] ?? '') as String,
      districtName: (m['districtName'] ?? '') as String,
      price: (m['price'] as num?)?.toDouble() ?? 0,
      photoUrl: (m['photoUrl'] as String?)?.trim().isNotEmpty == true
          ? (m['photoUrl'] as String)
          : null,
      sourceType: priceReportSourceTypeFromValue(m['sourceType'] as String?),
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}
