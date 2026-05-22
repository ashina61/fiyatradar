import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/price_reporting.dart';
import '../services/firebase_service.dart';

class AddPriceDuplicateResult {
  final String dedupeKey;
  final String groupId;
  final String message;

  const AddPriceDuplicateResult({
    required this.dedupeKey,
    required this.groupId,
    required this.message,
  });
}

class AddPriceSubmitResult {
  final bool createdReport;
  final bool incrementedVerification;
  final String groupId;
  final PriceReportSourceType sourceType;
  final AddPriceDuplicateResult? duplicate;

  const AddPriceSubmitResult({
    required this.createdReport,
    required this.incrementedVerification,
    required this.groupId,
    required this.sourceType,
    this.duplicate,
  });

  String get sourceLabel => priceReportSourceTypeLabelTr(sourceType);
}

class PriceReportService {
  PriceReportService(this._svc);

  final FirebaseService _svc;

  static String normalizeId(String value) {
    final lower = value.trim().toLowerCase();
    final safe = lower.replaceAll(RegExp(r'[^a-z0-9çğıöşü]+', unicode: true), '_');
    return safe.replaceAll(RegExp(r'_+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }

  static String buildGroupId({
    required String productId,
    required String chainId,
    required String cityId,
    required String districtId,
  }) {
    return '${normalizeId(productId)}_${normalizeId(chainId)}_${normalizeId(cityId)}_${normalizeId(districtId)}';
  }

  static String localDateKey(DateTime now) {
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '${now.year}$m$d';
  }

  static String dedupeKey({
    required String productId,
    required String chainId,
    required String cityId,
    required String districtId,
    required double price,
    required String yyyymmdd,
  }) {
    return '${normalizeId(productId)}|${normalizeId(chainId)}|${normalizeId(cityId)}|${normalizeId(districtId)}|${price.toStringAsFixed(2)}|$yyyymmdd';
  }

  Future<AddPriceSubmitResult> submitRegionalPrice({
    required String productId,
    required String productName,
    required String chainId,
    required String chainName,
    required String cityName,
    required String districtName,
    required double price,
    required String userId,
    required String userDisplayName,
    String? branchId,
    String? branchName,
    double? distanceToBranchMeters,
    double? gpsAccuracyMeters,
    GeoPoint? location,
    String? note,
    String? photoUrl,
    String? barcode,
    bool requiresReview = false,
    bool reporterIsPro = false,
    Future<void Function(Transaction tx, String reportId)> Function(Transaction tx)?
        prepareLegacyMirror,
  }) async {
    final cityId = normalizeId(cityName);
    final districtId = normalizeId(districtName);
    final normalizedChainId = normalizeId(chainId);
    final groupId = buildGroupId(
      productId: productId,
      chainId: normalizedChainId,
      cityId: cityId,
      districtId: districtId,
    );
    final now = DateTime.now();
    final dateKey = localDateKey(now);
    final deKey = dedupeKey(
      productId: productId,
      chainId: normalizedChainId,
      cityId: cityId,
      districtId: districtId,
      price: price,
      yyyymmdd: dateKey,
    );

    final sourceType = _resolveSourceType(
      distanceToBranchMeters: distanceToBranchMeters,
      hasLocation: location != null,
    );

    if (!requiresReview) {
      final duplicate = await _checkDuplicate(
        dedupeKeyValue: deKey,
        groupId: groupId,
        userId: userId,
        sourceType: sourceType,
      );
      if (duplicate != null) return duplicate;
    }

    final reportId = '${userId}_${now.millisecondsSinceEpoch}';
    final reportRef = _svc.priceReports.doc(reportId);
    final groupRef = _svc.priceGroups.doc(groupId);
    final dedupeRef = _svc.priceDedupes.doc(deKey);

    await _svc.db.runTransaction((tx) async {
      // Firestore kuralı: bir transaction içinde tüm okumalar tüm yazmalardan
      // önce yapılmalı. Bu yüzden ana groupRef okumasının yanında, çağıran
      // kodun ek okumalarını da burada (yazmalardan önce) yapmasına izin
      // veriyoruz; kendisi geri döndürdüğü closure ile yazma fazında devreye
      // girer.
      final groupSnap = requiresReview ? null : await tx.get(groupRef);
      final void Function(Transaction tx, String reportId)? legacyWrites =
          (!requiresReview && prepareLegacyMirror != null)
              ? await prepareLegacyMirror(tx)
              : null;

      final groupData = groupSnap?.data() ?? <String, dynamic>{};
      final currentCount = (groupData['reportCount'] as num?)?.toInt() ?? 0;
      final currentAvg = (groupData['avgPrice'] as num?)?.toDouble() ?? price;
      final minPrice = (groupData['minPrice'] as num?)?.toDouble();
      final maxPrice = (groupData['maxPrice'] as num?)?.toDouble();
      final currentVerified = (groupData['verifiedCount'] as num?)?.toInt() ?? 0;
      final currentPhotoCount = (groupData['photoReportCount'] as num?)?.toInt() ?? 0;

      final nextCount = currentCount + 1;
      final nextAvg =
          currentCount == 0 ? price : ((currentAvg * currentCount) + price) / nextCount;

      tx.set(reportRef, {
        'productId': productId,
        'productName': productName,
        'chainId': normalizedChainId,
        'chainName': chainName,
        'cityId': cityId,
        'cityName': cityName,
        'districtId': districtId,
        'districtName': districtName,
        'branchId': branchId,
        'branchName': branchName,
        'price': price,
        'currency': 'TRY',
        'sourceType': priceReportSourceTypeToValue(sourceType),
        'locationSource': location == null ? 'manual' : 'gps',
        'distanceToBranchMeters': distanceToBranchMeters,
        'gpsAccuracyMeters': gpsAccuracyMeters,
        'location': location,
        'photoUrl': photoUrl,
        'note': note,
        'barcode': barcode,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'reporterIsPro': reporterIsPro,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'localDateKey': dateKey,
        'status': requiresReview ? 'pending_photo_review' : 'active',
        'reviewReason': requiresReview ? 'photo_proof' : null,
        'dedupeKey': deKey,
        'groupId': groupId,
      });

      if (requiresReview) return;

      tx.set(dedupeRef, {
        'groupId': groupId,
        'reportId': reportId,
        'dedupeKey': deKey,
        'verifiedCount': 1,
        'verifierUserIds': {userId: true},
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      tx.set(groupRef, {
        'productId': productId,
        'productName': productName,
        'chainId': normalizedChainId,
        'chainName': chainName,
        'cityId': cityId,
        'cityName': cityName,
        'districtId': districtId,
        'districtName': districtName,
        'latestPrice': price,
        'trustedPrice': _calculateTrustedPrice(
          incomingPrice: price,
          sourceType: sourceType,
          existingTrustedPrice: (groupData['trustedPrice'] as num?)?.toDouble(),
        ),
        'minPrice': minPrice == null ? price : (price < minPrice ? price : minPrice),
        'maxPrice': maxPrice == null ? price : (price > maxPrice ? price : maxPrice),
        'avgPrice': nextAvg,
        'reportCount': nextCount,
        'verifiedCount': currentVerified,
        'photoReportCount': currentPhotoCount + (photoUrl == null ? 0 : 1),
        'lastReportedAt': FieldValue.serverTimestamp(),
        'lastReporterId': userId,
        'confidence': _resolveConfidence(nextCount, currentVerified),
        'sourceType': priceReportSourceTypeToValue(sourceType),
        'displayTitle': '$chainName · $districtName / $cityName',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Legacy mirror writes (priceEntries collection + products.priceHistory
      // array). Çağıran kod gerekli okumaları zaten transaction'ın okuma
      // fazında yaptı; burada yalnızca yazmalar çalıştırılır.
      legacyWrites?.call(tx, reportId);
    });

    return AddPriceSubmitResult(
      createdReport: true,
      incrementedVerification: false,
      groupId: groupId,
      sourceType: sourceType,
    );
  }

  Future<AddPriceSubmitResult?> _checkDuplicate({
    required String dedupeKeyValue,
    required String groupId,
    required String userId,
    required PriceReportSourceType sourceType,
  }) async {
    final dedupeSnap = await _svc.priceDedupes.doc(dedupeKeyValue).get();
    if (!dedupeSnap.exists) return null;
    final data = dedupeSnap.data() ?? <String, dynamic>{};
    final verifiers =
        Map<String, dynamic>.from(data['verifierUserIds'] as Map? ?? const {});
    if (verifiers.containsKey(userId)) {
      throw StateError('Bu fiyatı bugün zaten doğruladın.');
    }
    return AddPriceSubmitResult(
      createdReport: false,
      incrementedVerification: false,
      groupId: groupId,
      sourceType: sourceType,
      duplicate: AddPriceDuplicateResult(
        dedupeKey: dedupeKeyValue,
        groupId: groupId,
        message: 'Bu fiyat bugün bu bölgede zaten bildirilmiş.',
      ),
    );
  }

  Future<void> verifySeenToday({
    required String productId,
    required String chainId,
    required String cityName,
    required String districtName,
    required double price,
    required String userId,
  }) async {
    final dateKey = localDateKey(DateTime.now());
    final dedupeKeyValue = dedupeKey(
      productId: productId,
      chainId: chainId,
      cityId: normalizeId(cityName),
      districtId: normalizeId(districtName),
      price: price,
      yyyymmdd: dateKey,
    );
    final dedupeRef = _svc.priceDedupes.doc(dedupeKeyValue);

    await _svc.db.runTransaction((tx) async {
      final snap = await tx.get(dedupeRef);
      if (!snap.exists) {
        throw StateError('Bu fiyat için bugün doğrulanacak kayıt bulunamadı.');
      }
      final data = snap.data() ?? <String, dynamic>{};
      final verifiers =
          Map<String, dynamic>.from(data['verifierUserIds'] as Map? ?? const {});
      if (verifiers.containsKey(userId)) {
        throw StateError('Bu fiyatı bugün zaten doğruladın.');
      }
      final groupId = (data['groupId'] ?? '') as String;
      tx.update(dedupeRef, {
        'verifiedCount': FieldValue.increment(1),
        'verifierUserIds.$userId': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (groupId.isNotEmpty) {
        tx.set(_svc.priceGroups.doc(groupId), {
          'verifiedCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  PriceReportSourceType _resolveSourceType({
    required double? distanceToBranchMeters,
    required bool hasLocation,
  }) {
    if (distanceToBranchMeters != null && distanceToBranchMeters <= 30) {
      return PriceReportSourceType.branchNear;
    }
    if (hasLocation) {
      return PriceReportSourceType.locationSupported;
    }
    return PriceReportSourceType.manualRegional;
  }

  double _calculateTrustedPrice({
    required double incomingPrice,
    required PriceReportSourceType sourceType,
    required double? existingTrustedPrice,
  }) {
    if (sourceType == PriceReportSourceType.branchNear || existingTrustedPrice == null) {
      return incomingPrice;
    }
    return existingTrustedPrice;
  }

  String _resolveConfidence(int reportCount, int verifiedCount) {
    final signal = reportCount + verifiedCount;
    if (signal >= 10) return 'high';
    if (signal >= 4) return 'medium';
    return 'low';
  }
}
