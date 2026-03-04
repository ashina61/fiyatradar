import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cart_item.dart';

abstract class CartRepository {
  Stream<List<CartItem>> watchCartItems(String userId);
  Future<void> addOrUpdateItem(String userId, CartItem item);
  Future<void> updateQuantity(String userId, String itemId, int quantity);
  Future<void> removeItem(String userId, String itemId);
}

class FirestoreCartRepository implements CartRepository {
  FirestoreCartRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _cartRef(String userId) {
    return _firestore.collection('users').doc(userId).collection('cartItems');
  }

  @override
  Stream<List<CartItem>> watchCartItems(String userId) {
    return _cartRef(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(CartItem.fromFirestore).toList());
  }

  @override
  Future<void> addOrUpdateItem(String userId, CartItem item) {
    return _cartRef(userId).doc(item.id).set(item.toFirestore(), SetOptions(merge: true));
  }

  @override
  Future<void> updateQuantity(String userId, String itemId, int quantity) {
    if (quantity <= 0) {
      return removeItem(userId, itemId);
    }
    return _cartRef(userId).doc(itemId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeItem(String userId, String itemId) {
    return _cartRef(userId).doc(itemId).delete();
  }
}
