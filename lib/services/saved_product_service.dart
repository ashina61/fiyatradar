import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product_model.dart';

class SavedProductService {
  SavedProductService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  Stream<List<ProductModel>> getSavedProducts(List<String> productIds) {
    if (productIds.isEmpty) {
      return Stream.value([]);
    }

    final uniqueIds = productIds.toSet().toList();
    return _productsRef.snapshots().map((snapshot) {
      final productMap = <String, ProductModel>{};
      for (final doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        if (uniqueIds.contains(product.id)) {
          productMap[product.id] = product;
        }
      }
      return uniqueIds.where(productMap.containsKey).map((id) => productMap[id]!).toList();
    });
  }
}
