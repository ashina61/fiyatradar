import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/product_detail_api_model.dart';
import '../models/product_model.dart';
import 'firestore_service.dart';

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

      _log(
        '[ProductDetailApiService.fetchProductDetails] Firestore query => collection=priceReports, where=[productId == $productId, status == active], orderBy=[]',
      );
      final pricesSnapshot = await _pricesRef
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'active')
          .get();
      final prices = pricesSnapshot.docs.map(PriceModel.fromFirestore).toList();

      _log(
        '[ProductDetailApiService.fetchProductDetails] Firestore query => collection=comments, where=[productId == $productId], orderBy=[]',
      );
      final commentsSnapshot = await _commentsRef
          .where('productId', isEqualTo: productId)
          .get();
      final comments = commentsSnapshot.docs
          .map(CommentModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      final latestPriceModel = prices.isNotEmpty
          ? prices.reduce(
              (current, next) =>
                  next.reportedAt.isAfter(current.reportedAt) ? next : current,
            )
          : null;
      final stats = _buildStats(prices);
      final trust = _buildTrust(prices);

      return ProductDetailResponse(
        id: product.id,
        title: product.name,
        imageUrl: product.effectiveImage ?? '',
        categories: product.categories,
        viewCount: product.viewCount,
        priceEntryCount: prices.length,
        bestPrice: _toBestPrice(latestPriceModel),
        stats: stats,
        trust: trust,
        comments: comments.map(_toProductComment).toList(growable: false),
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
      final since = now.subtract(const Duration(days: 30));

      _log(
        '[ProductDetailApiService.fetchPriceHistory] Firestore query => collection=priceReports, where=[productId == $productId, status == active, reportedAt >= ${Timestamp.fromDate(since)}], orderBy=[]',
      );
      final snapshot = await _pricesRef
          .where('productId', isEqualTo: productId)
          .where('status', isEqualTo: 'active')
          .get();

      final prices = snapshot.docs
          .map(PriceModel.fromFirestore)
          .where((price) => !price.reportedAt.isBefore(since))
          .toList()
        ..sort((a, b) => a.reportedAt.compareTo(b.reportedAt));

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
      userName: (userData['name'] ?? userData['displayName'] ?? user.displayName ?? 'Anonim').toString(),
      userPhotoUrl: (userData['photoUrl'] ?? user.photoURL)?.toString(),
      authorRole: (userData['role'] ?? 'member').toString(),
      text: trimmed,
      createdAt: DateTime.now(),
    );

    await _firestoreService.addComment(comment);
  }

  Future<void> votePrice(String priceId, bool isApproved) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Oy vermek için giriş yapmalısın.');
    }

    await _firestoreService.verifyPrice(priceId, user.uid, isApproved);
  }

  BestPrice _toBestPrice(PriceModel? price) {
    if (price == null) {
      return BestPrice(
        id: '',
        userId: '',
        price: 0,
        store: '',
        userName: 'Topluluk',
        userTier: 'Yeni',
        createdAtLabel: '-',
        storeUrl: '',
        storeId: '',
        storeLocation: '',
        upVotes: 0,
        downVotes: 0,
        userTrustScore: 0,
      );
    }

    final storeId = (price.selectedStoreId ?? price.branchStoreId).trim();
    final storeLocation = (price.storeLocation ?? '').trim();

    return BestPrice(
      id: price.id,
      userId: (price.createdByUid ?? price.userId).trim(),
      price: price.price,
      store: price.storeName ?? 'Bilinmeyen mağaza',
      userName: (price.userName ?? 'Anonim').trim().isEmpty ? 'Anonim' : price.userName!,
      userTier: (price.addedByLevelSnapshot ?? price.createdByBadgeSnapshot ?? 'Topluluk').toString(),
      createdAtLabel: _formatTimeAgo(price.reportedAt),
      storeUrl: storeLocation,
      storeId: storeId,
      storeLocation: storeLocation,
      upVotes: price.upVotes,
      downVotes: price.downVotes,
      userTrustScore: price.addedByTrustScoreSnapshot.round(),
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


  Future<LatLng?> resolveStoreCoordinates(BestPrice bestPrice) async {
    final direct = _parseCoordinatesFromText(bestPrice.storeLocation);
    if (direct != null) return direct;

    if (bestPrice.storeId.isNotEmpty) {
      final storeDoc = await _storesRef.doc(bestPrice.storeId).get();
      if (storeDoc.exists) {
        final data = storeDoc.data() ?? const <String, dynamic>{};
        final parsed = _parseCoordinatesFromDynamic(data);
        if (parsed != null) return parsed;
      }
    }
    return null;
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

  ProductComment _toProductComment(CommentModel comment) {
    return ProductComment(
      id: comment.id,
      author: comment.userName,
      avatarBgHex: '#C8956C',
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
