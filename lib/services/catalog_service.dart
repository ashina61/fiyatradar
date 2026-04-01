import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../utils/safe_query_builder.dart';

class CatalogService {
  CatalogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final Set<String> _offFetchInFlight = <String>{};

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _pricesRef =>
      _firestore.collection('priceReports');
  CollectionReference<Map<String, dynamic>> get _commentsRef =>
      _firestore.collection('comments');

  Stream<List<ProductModel>> getTrendingProducts({int limit = 10}) {
    return _productsRef
        .orderBy('priceEntryCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      return list;
    });
  }

  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _productsRef
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      return list;
    });
  }


  Stream<List<ProductModel>> getEditorPickProducts({int limit = 1}) {
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).where((p) => p.isEditorPick).toList();
      list.sort((a, b) {
        final rankA = a.editorPickRank ?? 1 << 30;
        final rankB = b.editorPickRank ?? 1 << 30;
        final byRank = rankA.compareTo(rankB);
        if (byRank != 0) return byRank;
        return b.updatedAt?.compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)) ?? 0;
      });
      return list.take(limit).toList();
    });
  }

  /// Intentionally capped for listing performance.
  /// If a full catalog is required in future, pagination should be implemented.
  Stream<List<ProductModel>> getAllProducts({int limit = 200}) {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      if (kDebugMode && list.length == limit) {
        debugPrint(
          '[CatalogService.getAllProducts] reached cap ($limit). Consider pagination for full catalog use-cases.',
        );
      }
      for (final product in list) {
        _ensureOpenFoodFactsImage(product);
      }
      return list;
        });
  }

  Future<({
    List<ProductModel> products,
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc,
    bool hasMore,
  })> getProductsPage({
    int pageSize = 60,
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final safePageSize = pageSize < 1 ? 1 : pageSize;
    Query<Map<String, dynamic>> query = _productsRef
        .orderBy('createdAt', descending: true)
        .limit(safePageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    final products = snapshot.docs
        .map(ProductModel.fromFirestore)
        .toList(growable: false);
    return (
      products: products,
      lastDoc: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      hasMore: snapshot.docs.length == safePageSize,
    );
  }

  Future<List<ProductModel>> searchProducts(String query, {int limit = 50}) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return const [];
    final safeLimit = limit < 1 ? 1 : limit;

    final byKeywordSnapshot = await _productsRef
        .where('searchKeywords', arrayContains: normalizedQuery)
        .limit(safeLimit)
        .get();

    QuerySnapshot<Map<String, dynamic>> byPrefixSnapshot;
    try {
      byPrefixSnapshot = await _productsRef
          .where('name_lowercase', isGreaterThanOrEqualTo: normalizedQuery)
          .where('name_lowercase', isLessThan: '$normalizedQuery\uf8ff')
          .orderBy('name_lowercase')
          .limit(safeLimit)
          .get();
    } catch (_) {
      byPrefixSnapshot = await _productsRef.limit(0).get();
    }

    final merged = <String, ProductModel>{};
    for (final doc in [...byKeywordSnapshot.docs, ...byPrefixSnapshot.docs]) {
      final product = ProductModel.fromFirestore(doc);
      final haystack = '${product.name} ${product.brand} ${product.barcode ?? ''}'
          .toLowerCase();
      if (!haystack.contains(normalizedQuery)) continue;
      merged[product.id] = product;
    }

    final results = merged.values.toList(growable: false);
    results.sort((a, b) {
      final aExact = a.name.trim().toLowerCase() == normalizedQuery ? 0 : 1;
      final bExact = b.name.trim().toLowerCase() == normalizedQuery ? 0 : 1;
      if (aExact != bExact) return aExact.compareTo(bExact);
      final aPrefix = a.name.trim().toLowerCase().startsWith(normalizedQuery) ? 0 : 1;
      final bPrefix = b.name.trim().toLowerCase().startsWith(normalizedQuery) ? 0 : 1;
      if (aPrefix != bPrefix) return aPrefix.compareTo(bPrefix);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    if (results.isNotEmpty) {
      return results.take(safeLimit).toList(growable: false);
    }

    final barcodeSnapshot = await _productsRef
        .where('barcode', isEqualTo: query.trim())
        .limit(safeLimit)
        .get();
    return barcodeSnapshot.docs
        .map(ProductModel.fromFirestore)
        .toList(growable: false);
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (!doc.exists) return null;
    final product = ProductModel.fromFirestore(doc);
    await _ensureOpenFoodFactsImage(product);
    return product;
  }

  Stream<ProductModel?> getProductStream(String productId) {
    if (productId.trim().isEmpty) return Stream.value(null);
    return _productsRef.doc(productId).snapshots().asyncMap((doc) async {
      if (!doc.exists) return null;
      final product = ProductModel.fromFirestore(doc);
      await _ensureOpenFoodFactsImage(product);
      return product;
    });
  }

  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Stream<List<PriceModel>> getPricesForProduct(String productId) {
    var query =
        SafeQueryBuilder.safeWhere(_pricesRef, 'productId', productId, expectedType: String);
    query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(PriceModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<PriceModel>> getLatestPrices({int limit = 10}) {
    var query = SafeQueryBuilder.safeWhere(_pricesRef, 'status', 'active', expectedType: String);
    query = query.orderBy('createdAt', descending: true).limit(limit);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(PriceModel.fromFirestore).toList();
      return list;
    });
  }

  Stream<List<CommentModel>> getComments(String productId) {
    var query =
        SafeQueryBuilder.safeWhere(_commentsRef, 'productId', productId, expectedType: String);
    query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(CommentModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> _ensureOpenFoodFactsImage(ProductModel product) async {
    if ((product.effectiveImage ?? '').isNotEmpty) return;
    final barcode = product.barcode?.trim() ?? '';
    if (barcode.isEmpty || _offFetchInFlight.contains(product.id)) return;
    _offFetchInFlight.add(product.id);

    try {
      final uri = Uri.parse(
        'https://world.openfoodfacts.org/api/v2/product/$barcode.json',
      );
      final response = await _getBytes(uri, headers: const {
        'User-Agent': 'FiyatRadar/1.0 (image-fallback)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final productData = body['product'] as Map<String, dynamic>?;
      final imageFront = (productData?['image_front_url'] ?? '').toString();
      if (imageFront.isEmpty) return;

      await _productsRef.doc(product.id).set({
        'imageUrl': imageFront,
        'mainImage': imageFront,
        'imageSource': 'openfoodfacts',
        'imageApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // best effort fallback
    } finally {
      _offFetchInFlight.remove(product.id);
    }
  }

  Future<_HttpBytesResponse> _getBytes(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      headers?.forEach(request.headers.set);
      final response = await request.close();
      final bodyBytes = await consolidateHttpClientResponseBytes(response);
      return _HttpBytesResponse(response.statusCode, bodyBytes);
    } finally {
      client.close(force: true);
    }
  }
}

class _HttpBytesResponse {
  const _HttpBytesResponse(this.statusCode, this.bodyBytes);

  final int statusCode;
  final Uint8List bodyBytes;
}
