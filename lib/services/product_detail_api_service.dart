import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/product_detail_api_model.dart';
import '../models/product_model.dart';
import '../utils/elite_level_engine.dart';
import 'firestore_service.dart';

class StoreNavigationPayload {
  const StoreNavigationPayload({
    this.coordinates,
    this.mapsUrl,
    this.address,
  });

  final LatLng? coordinates;
  final String? mapsUrl;
  final String? address;
}


class _UserProfileLite {
  const _UserProfileLite({
    required this.level,
    required this.photoUrl,
  });

  final String level;
  final String photoUrl;
}

class ProductDetailPriceSnapshot {
  const ProductDetailPriceSnapshot({
    required this.priceEntryCount,
    required this.bestPrice,
    required this.stats,
    required this.trust,
    required this.marketPrices,
    required this.recentPrices,
  });

  final int priceEntryCount;
  final BestPrice bestPrice;
  final PriceStats stats;
  final TrustStats trust;
  final List<MarketPriceEntry> marketPrices;
  final List<RecentPriceEntry> recentPrices;
}

class ProductDetailApiService {
  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  ProductDetailApiService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirestoreService? firestoreService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreService _firestoreService;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _pricesRef =>
      _firestore.collection('priceReports');
  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('comments');
  CollectionReference<Map<String, dynamic>> get _storesRef =>
      _firestore.collection('stores');

  static const int _initialPricesLimit = 120;
  static const int _initialCommentsLimit = 40;
  static const int _historyLimit = 240;

  Future<ProductDetailResponse> fetchProductDetails(String productId) async {
    try {
      _log(
        '[ProductDetailApiService.fetchProductDetails] Firestore query => collection=products, where=[documentId == $productId], orderBy=[]',
      );
      final productDoc = await _productsRef.doc(productId).get();
      if (!productDoc.exists) {
        throw Exception('Ürün bulunamadı.');
      }

      final product = ProductModel.fromFirestore(productDoc);

      final priceSnapshot = await fetchPriceSnapshot(productId);
      final comments = await fetchComments(
        productId,
        limit: _initialCommentsLimit,
      );

      return ProductDetailResponse(
        id: product.id,
        title: product.name,
        imageUrl: product.effectiveImage ?? '',
        categories: product.categories,
        viewCount: product.viewCount,
        priceEntryCount: priceSnapshot.priceEntryCount,
        bestPrice: priceSnapshot.bestPrice,
        stats: priceSnapshot.stats,
        trust: priceSnapshot.trust,
        comments: comments,
        marketPrices: priceSnapshot.marketPrices,
        recentPrices: priceSnapshot.recentPrices,
      );
    } catch (e, st) {
      _log('[ProductDetailApiService.fetchProductDetails] ERROR: $e');
      if (kDebugMode) {
        debugPrintStack(
          stackTrace: st,
          label: '[ProductDetailApiService.fetchProductDetails] STACK',
        );
      }
      rethrow;
    }
  }

  Future<List<PriceHistoryPoint>> fetchPriceHistory(String productId) async {
    try {
      final now = DateTime.now();
      final since = now.subtract(const Duration(days: 90));

      _log(
        '[ProductDetailApiService.fetchPriceHistory] Firestore query => collection=priceReports, where=[productId == $productId, status == active, reportedAt >= ${Timestamp.fromDate(since)}], orderBy=[reportedAt asc], limit=$_historyLimit',
      );
      final snapshot = await _pricesRef
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'active')
          .where('reportedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
          .orderBy('reportedAt')
          .limit(_historyLimit)
          .get();

      final prices = snapshot.docs
          .map(PriceModel.fromFirestore)
          .toList(growable: false);

      final uniqueById = <String, PriceModel>{};
      for (final price in prices) {
        uniqueById[price.id] = price;
      }
      final dedupeMap = <String, PriceModel>{};
      for (final price in uniqueById.values) {
        final key = price.dedupeKey?.trim().isNotEmpty == true
            ? price.dedupeKey!.trim()
            : '${price.productId}|${price.branchStoreId}|${price.price.toStringAsFixed(2)}|${DateFormat('yyyy-MM-dd').format(price.reportedAt)}';
        final existing = dedupeMap[key];
        if (existing == null || price.reportedAt.isAfter(existing.reportedAt)) {
          dedupeMap[key] = price;
        }
      }
      final points = dedupeMap.values.toList()
        ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));

      final formatter = DateFormat('dd MMM', 'tr_TR');
      return points
          .map(
            (price) => PriceHistoryPoint(
              dateLabel: formatter.format(price.reportedAt),
              price: price.price,
              reportedAt: price.reportedAt,
            ),
          )
          .toList(growable: false);
    } catch (e, st) {
      _log('[ProductDetailApiService.fetchPriceHistory] ERROR: $e');
      if (kDebugMode) {
        debugPrintStack(
          stackTrace: st,
          label: '[ProductDetailApiService.fetchPriceHistory] STACK',
        );
      }
      rethrow;
    }
  }

  Future<void> postComment(String productId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      throw Exception('Yorum boş olamaz.');
    }

    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Yorum yapmak için giriş yapmalısın.');
    }

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() ?? <String, dynamic>{};

    final comment = CommentModel(
      id: '',
      productId: productId,
      userId: user.uid,
      userName: (userData['username'] ?? user.email?.split('@').first ?? user.uid).toString(),
      userPhotoUrl: (userData['photoUrl'] ?? user.photoURL)?.toString(),
      authorRole: (userData['role'] ?? 'member').toString(),
      text: trimmed,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addComment(comment);
  }

  Future<PriceVoteResult> votePrice(String priceId, bool isApproved) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Oy vermek için giriş yapmalısın.');
    }

    return _firestoreService.verifyPrice(priceId, user.uid, isApproved);
  }

  Future<ProductDetailPriceSnapshot> fetchPriceSnapshot(
    String productId, {
    int limit = _initialPricesLimit,
  }) async {
    final activePricesQuery = _pricesRef
        .where('productId', isEqualTo: productId)
        .where('status', isEqualTo: 'active');

    int totalActivePriceCount;
    try {
      _log(
        '[ProductDetailApiService.fetchPriceSnapshot] Firestore aggregate => collection=priceReports, where=[productId == $productId, status == active], aggregate=[count]',
      );
      final countSnapshot = await activePricesQuery.count().get();
      totalActivePriceCount = countSnapshot.count;
    } catch (e, st) {
      _log(
        '[ProductDetailApiService.fetchPriceSnapshot] aggregate count failed, fallback to limited snapshot length: $e',
      );
      if (kDebugMode) {
        debugPrintStack(
          stackTrace: st,
          label: '[ProductDetailApiService.fetchPriceSnapshot] AGGREGATE STACK',
        );
      }
      totalActivePriceCount = 0;
    }

    _log(
      '[ProductDetailApiService.fetchPriceSnapshot] Firestore query => collection=priceReports, where=[productId == $productId, status == active], orderBy=[reportedAt desc], limit=$limit',
    );
    final pricesSnapshot = await activePricesQuery
        .orderBy('reportedAt', descending: true)
        .limit(limit)
        .get();

    final prices = pricesSnapshot.docs
        .map(PriceModel.fromFirestore)
        .toList(growable: false);
    final latestPriceModel = prices.isNotEmpty ? prices.first : null;
    final resolvedTotalCount =
        totalActivePriceCount > 0 ? totalActivePriceCount : prices.length;

    return ProductDetailPriceSnapshot(
      priceEntryCount: resolvedTotalCount,
      bestPrice: _toBestPrice(latestPriceModel),
      stats: _buildStats(prices),
      trust: _buildTrust(prices),
      marketPrices: _buildMarketPrices(prices),
      recentPrices: _buildRecentPrices(prices),
    );
  }

  Future<List<ProductComment>> fetchComments(
    String productId, {
    int limit = _initialCommentsLimit,
  }) async {
    _log(
      '[ProductDetailApiService.fetchComments] Firestore query => collection=comments, where=[productId == $productId], orderBy=[createdAt desc], limit=$limit',
    );
    final commentsSnapshot = await _commentsRef
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    final comments = commentsSnapshot.docs
        .map(CommentModel.fromFirestore)
        .toList(growable: false);
    final commentAuthorProfiles = await _resolveUserProfiles(
      comments.map((c) => c.userId),
    );

    return comments
        .map(
          (comment) => _toProductComment(
            comment,
            authorLevel: commentAuthorProfiles[comment.userId]?.level ?? '',
            authorPhotoUrl: commentAuthorProfiles[comment.userId]?.photoUrl ?? comment.userPhotoUrl ?? '',
          ),
        )
        .toList(growable: false);
  }

  BestPrice _toBestPrice(PriceModel? price) {
    if (price == null) {
      return BestPrice(
        id: '',
        userId: '',
        price: 0,
        store: '',
        userName: '',
        userTier: '',
        createdAtLabel: '-',
        storeUrl: '',
        storeId: '',
        storeLocation: '',
        upVotes: 0,
        downVotes: 0,
        userTrustScore: 0,
        addedByVerifiedBadge: false,
        createdByVerifiedSnapshot: false,
      );
    }

    final storeId = (price.selectedStoreId ?? price.branchStoreId).trim();
    final storeLocation = (price.storeLocation ?? '').trim();

    return BestPrice(
      id: price.id,
      userId: (price.createdByUid ?? price.userId).trim(),
      price: price.price,
      store: (price.storeName ?? '').trim(),
      userName: (price.userName ?? '').trim(),
      userTier: (price.addedByLevelSnapshot ??
              price.createdByBadgeSnapshot ??
              _normalizeLevelLabel(price.trustLabel))
          .toString(),
      createdAtLabel: _formatTimeAgo(price.reportedAt),
      storeUrl: storeLocation,
      storeId: storeId,
      storeLocation: storeLocation,
      upVotes: price.upVotes,
      downVotes: price.downVotes,
      userTrustScore: price.addedByTrustScoreSnapshot.round(),
      addedByVerifiedBadge: price.addedByVerifiedBadge,
      createdByVerifiedSnapshot: price.createdByVerifiedSnapshot,
    );
  }

  PriceStats _buildStats(List<PriceModel> prices) {
    if (prices.isEmpty) {
      return PriceStats(lowest: 0, average: 0, highest: 0);
    }
    final values = prices.map((e) => e.price).toList(growable: false);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    return PriceStats(lowest: min, average: avg, highest: max);
  }

  TrustStats _buildTrust(List<PriceModel> prices) {
    final approveCount = prices.fold<int>(0, (sum, p) => sum + p.upVotes);
    final rejectCount = prices.fold<int>(0, (sum, p) => sum + p.downVotes);
    final total = approveCount + rejectCount;
    final scorePercent = total == 0 ? 0 : ((approveCount / total) * 100).round();
    return TrustStats(
      scorePercent: scorePercent,
      approveCount: approveCount,
      rejectCount: rejectCount,
    );
  }

  List<MarketPriceEntry> _buildMarketPrices(List<PriceModel> prices) {
    if (prices.isEmpty) return const [];
    final latestByStore = <String, PriceModel>{};
    for (final price in prices) {
      final key = [
        (price.selectedStoreId ?? '').trim(),
        price.branchStoreId.trim(),
        (price.storeName ?? '').trim().toLowerCase(),
      ].firstWhere((e) => e.isNotEmpty, orElse: () => 'unknown');
      final existing = latestByStore[key];
      if (existing == null || price.reportedAt.isAfter(existing.reportedAt)) {
        latestByStore[key] = price;
      }
    }

    final list = latestByStore.values.toList()
      ..sort((a, b) => a.price.compareTo(b.price));
    return list
        .map((price) => MarketPriceEntry(
              priceId: price.id,
              storeId: (price.selectedStoreId ?? price.branchStoreId).trim(),
              storeName: (price.storeName ?? 'Market').trim().isEmpty
                  ? 'Market'
                  : (price.storeName ?? 'Market').trim(),
              storeLocation: (price.storeLocation ?? '').trim(),
              storeUrl: (price.storeLocation ?? '').trim(),
              price: price.price,
              timeAgo: _formatTimeAgo(price.reportedAt),
              userName: (price.userName ?? 'Kullanıcı').trim().isEmpty
                  ? 'Kullanıcı'
                  : (price.userName ?? 'Kullanıcı').trim(),
              userId: (price.createdByUid ?? price.userId).trim(),
              upVotes: price.upVotes,
              downVotes: price.downVotes,
              isOnline: (price.storeLocation ?? '').toLowerCase().contains('online'),
            ))
        .toList(growable: false);
  }

  List<RecentPriceEntry> _buildRecentPrices(List<PriceModel> prices) {
    if (prices.isEmpty) return const [];
    final list = [...prices]..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
    return list
        .take(20)
        .map((price) => RecentPriceEntry(
              priceId: price.id,
              storeName: (price.storeName ?? 'Market').trim().isEmpty
                  ? 'Market'
                  : (price.storeName ?? 'Market').trim(),
              storeLocation: (price.storeLocation ?? '').trim(),
              price: price.price,
              timeAgo: _formatTimeAgo(price.reportedAt),
              userName: (price.userName ?? 'Kullanıcı').trim().isEmpty
                  ? 'Kullanıcı'
                  : (price.userName ?? 'Kullanıcı').trim(),
              userId: (price.createdByUid ?? price.userId).trim(),
              upVotes: price.upVotes,
              downVotes: price.downVotes,
            ))
        .toList(growable: false);
  }


  Future<LatLng?> resolveStoreCoordinates(BestPrice bestPrice) async {
    final payload = await resolveStoreNavigation(bestPrice);
    return payload?.coordinates;
  }

  Future<StoreNavigationPayload?> resolveStoreNavigation(BestPrice bestPrice) async {
    final direct = _parseCoordinatesFromText(bestPrice.storeLocation);
    if (direct != null) {
      return StoreNavigationPayload(
        coordinates: direct,
        mapsUrl: bestPrice.storeUrl,
        address: bestPrice.storeLocation,
      );
    }

    String? mapsUrl = bestPrice.storeUrl.trim().isEmpty ? null : bestPrice.storeUrl.trim();
    String? address = bestPrice.storeLocation.trim().isEmpty ? null : bestPrice.storeLocation.trim();
    LatLng? coordinates;

    if (bestPrice.storeId.isNotEmpty) {
      final storeDoc = await _storesRef.doc(bestPrice.storeId).get();
      if (storeDoc.exists) {
        final data = storeDoc.data() ?? const <String, dynamic>{};
        coordinates = _parseCoordinatesFromDynamic(data);
        mapsUrl ??= _readFirstNonEmptyString(data, const [
          'mapsUrl',
          'mapUrl',
          'googleMapsUrl',
          'locationUrl',
        ]);
        address ??= _readFirstNonEmptyString(data, const ['address', 'fullAddress']);
      }
    }

    if (coordinates == null && mapsUrl == null && address == null) {
      return null;
    }

    return StoreNavigationPayload(
      coordinates: coordinates,
      mapsUrl: mapsUrl,
      address: address,
    );
  }

  LatLng? _parseCoordinatesFromDynamic(Map<String, dynamic> data) {
    final lat = _toDouble(data['lat'] ?? data['latitude']);
    final lng = _toDouble(data['lng'] ?? data['longitude'] ?? data['lon']);
    if (lat != null && lng != null) return LatLng(lat, lng);

    final geo = data['geoPoint'] ?? data['location'] ?? data['coordinates'] ?? data['geo'];
    if (geo is GeoPoint) return LatLng(geo.latitude, geo.longitude);
    if (geo is Map) {
      final map = Map<String, dynamic>.from(geo);
      final mapLat = _toDouble(map['lat'] ?? map['latitude']);
      final mapLng = _toDouble(map['lng'] ?? map['longitude'] ?? map['lon']);
      if (mapLat != null && mapLng != null) return LatLng(mapLat, mapLng);
    }
    if (geo is String) return _parseCoordinatesFromText(geo);
    return null;
  }

  LatLng? _parseCoordinatesFromText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final matches = RegExp(r'-?\d+(?:[\.,]\d+)?').allMatches(text).map((m) => m.group(0) ?? '').toList();
    if (matches.length < 2) return null;
    final lat = _toDouble(matches[0]);
    final lng = _toDouble(matches[1]);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.').trim());
    return null;
  }

  String? _readFirstNonEmptyString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }


  Future<Map<String, _UserProfileLite>> _resolveUserProfiles(Iterable<String> userIds) async {
    final ids = userIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toSet().toList(growable: false);
    if (ids.isEmpty) return const <String, _UserProfileLite>{};

    final result = <String, _UserProfileLite>{};
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      final end = (i + 10 < ids.length) ? (i + 10) : ids.length;
      chunks.add(ids.sublist(i, end));
    }

    for (final chunk in chunks) {
      final snapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final level = _extractLevelLabel(data);
        final photoUrl = _readFirstNonEmptyString(data, const ['photoUrl', 'photoURL', 'imageUrl']) ?? '';
        result[doc.id] = _UserProfileLite(level: level, photoUrl: photoUrl);
      }
    }

    return result;
  }

  String _extractLevelLabel(Map<String, dynamic> data) {
    final direct = _normalizeLevelLabel(data['level'] ?? data['levelName'] ?? data['tierName']);
    if (direct.isNotEmpty) return direct;

    final totalPoints = (data['totalPoints'] as num?)?.toInt() ??
        (data['pointsTotal'] as num?)?.toInt() ??
        (data['points'] as num?)?.toInt() ??
        0;
    final trustPercent = ((data['trustScorePercent'] as num?)?.toInt() ??
            (data['reliabilityScore'] as num?)?.toInt() ??
            0)
        .clamp(0, 100);
    final trustVotes = (data['trustTotalVotes'] as num?)?.toInt() ?? 0;
    final finalLevel = EliteLevelEngine.getFinalLevel(totalPoints, trustPercent, trustVotes);
    return EliteLevelEngine.getLevelStyle(finalLevel).label;
  }

  String _normalizeLevelLabel(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return '';
    return EliteLevelEngine.getLevelStyle(EliteLevelEngine.parseLevelLabel(raw)).label;
  }

  ProductComment _toProductComment(CommentModel comment, {required String authorLevel, required String authorPhotoUrl}) {
    return ProductComment(
      id: comment.id,
      authorId: comment.userId,
      author: comment.userName,
      authorLevel: authorLevel,
      authorPhotoUrl: authorPhotoUrl,
      avatarBgHex: '',
      text: comment.text,
      timeAgo: _formatTimeAgo(comment.createdAt),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} sa önce';
    if (diff.inDays < 30) return '${diff.inDays} gün önce';
    final months = (diff.inDays / 30).floor();
    return '$months ay önce';
  }
}
