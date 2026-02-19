import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

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
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      list.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
      return list.take(limit).toList();
    });
  }

  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      return list.take(limit).toList();
    });
  }

  Stream<List<ProductModel>> getAllProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ProductModel.fromFirestore).toList();
      for (final product in list) {
        _ensureOpenFoodFactsImage(product);
      }
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<List<ProductModel>> searchProducts(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _productsRef.get();
    return snapshot.docs
        .map(ProductModel.fromFirestore)
        .where(
          (product) =>
              product.name.toLowerCase().contains(queryLower) ||
              product.brand.toLowerCase().contains(queryLower) ||
              (product.barcode?.contains(query) ?? false),
        )
        .toList();
  }

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (!doc.exists) return null;
    final product = ProductModel.fromFirestore(doc);
    await _ensureOpenFoodFactsImage(product);
    return product;
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
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(PriceModel.fromFirestore).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list.take(limit).toList();
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
      final response = await http.get(uri, headers: const {
        'User-Agent': 'FiyatRadar/1.0 (image-fallback)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
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
}
