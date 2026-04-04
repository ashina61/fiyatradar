import 'package:cloud_firestore/cloud_firestore.dart';

class BasketDataService {
  BasketDataService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _basketRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('basketItems');
  }

  Stream<List<Map<String, dynamic>>> getBasketItems(String userId) {
    return _basketRef(userId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  Future<void> upsertBasketItem({
    required String userId,
    required String productId,
    required int quantity,
    double? lastKnownPrice,
    bool includeLastKnownPrice = false,
  }) async {
    await _basketRef(userId).doc(productId).set({
      'productId': productId,
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
      if (includeLastKnownPrice) 'lastKnownPrice': lastKnownPrice,
    }, SetOptions(merge: true));
  }

  Future<void> removeBasketItem({
    required String userId,
    required String productId,
  }) async {
    await _basketRef(userId).doc(productId).delete();
  }
}
