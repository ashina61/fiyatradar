import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class ProductCatalogService {
  ProductCatalogService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  Stream<List<ProductModel>> getTrendingProducts({int limit = 10}) {
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
      return list.take(limit).toList();
    });
  }

  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _productsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => ProductModel.fromFirestore(doc)).toList();
      list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
      return list.take(limit).toList();
    });
  }

  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    if (productIds.isEmpty) return const [];

    final uniqueIds = productIds.toSet().toList();
    final futures = uniqueIds.map((id) => _productsRef.doc(id).get());
    final docs = await Future.wait(futures);
    final productMap = <String, ProductModel>{};
    for (final doc in docs) {
      if (!doc.exists) continue;
      final model = ProductModel.fromFirestore(doc);
      productMap[model.id] = model;
    }

    return uniqueIds.where(productMap.containsKey).map((id) => productMap[id]!).toList();
  }

  Future<String> addProduct(ProductModel product) async {
    final doc = await _productsRef.add(product.toFirestore());
    return doc.id;
  }

  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _productsRef.doc(productId).update(data);
  }

  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }
}
