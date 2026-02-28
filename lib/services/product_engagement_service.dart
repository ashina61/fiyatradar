import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEngagementService {
  ProductEngagementService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  Future<void> registerProductShare({
    required String productId,
    String? uid,
    Map<String, dynamic>? payload,
  }) async {
    final shareRef = _firestore.collection('product_shares').doc();
    await shareRef.set({
      'productId': productId,
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
      ...?payload,
    });

    await _productsRef.doc(productId).set({
      'shareCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
