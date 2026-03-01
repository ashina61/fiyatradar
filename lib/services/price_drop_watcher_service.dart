import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PriceDropWatcherService {
  PriceDropWatcherService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _watchlistSubscription;
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>>
      _productSubscriptions = {};

  String? _activeUid;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;

    _authSubscription = _auth.authStateChanges().listen((user) {
      final uid = user?.uid;
      if (uid == _activeUid) return;
      _resetUserSubscriptions();
      _activeUid = uid;
      if (uid != null && uid.isNotEmpty) {
        _startWatchlistListener(uid);
      }
    });

    final currentUid = _auth.currentUser?.uid;
    if (currentUid != null && currentUid.isNotEmpty) {
      _activeUid = currentUid;
      _startWatchlistListener(currentUid);
    }
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    _authSubscription = null;
    _resetUserSubscriptions();
    _started = false;
  }

  void _startWatchlistListener(String uid) {
    _watchlistSubscription = _firestore
        .collection('users')
        .doc(uid)
        .collection('watchlist')
        .snapshots()
        .listen((snapshot) {
      final nextProductIds = snapshot.docs.map((doc) => doc.id).toSet();

      final removed = _productSubscriptions.keys
          .where((productId) => !nextProductIds.contains(productId))
          .toList(growable: false);
      for (final productId in removed) {
        _productSubscriptions.remove(productId)?.cancel();
      }

      for (final productId in nextProductIds) {
        _productSubscriptions.putIfAbsent(
          productId,
          () => _firestore.collection('products').doc(productId).snapshots().listen(
            (productDoc) => _handleProductSnapshot(
              uid: uid,
              productId: productId,
              productDoc: productDoc,
            ),
          ),
        );
      }
    });
  }

  Future<void> _handleProductSnapshot({
    required String uid,
    required String productId,
    required DocumentSnapshot<Map<String, dynamic>> productDoc,
  }) async {
    final productData = productDoc.data();
    if (productData == null) return;

    final lowestRaw = productData['lowestPrice'];
    if (lowestRaw is! num) return;

    final lowestPrice = lowestRaw.toDouble();
    final watchStateRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('watchState')
        .doc(productId);

    final notificationRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('inAppNotifications')
        .doc();

    await _firestore.runTransaction((txn) async {
      final watchStateDoc = await txn.get(watchStateRef);
      final watchStateData = watchStateDoc.data();
      final previousLowest = (watchStateData?['lastNotifiedLowestPrice'] as num?)?.toDouble();

      if (previousLowest == null) {
        txn.set(watchStateRef, {
          'lastNotifiedLowestPrice': lowestPrice,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return;
      }

      if (lowestPrice >= previousLowest) {
        return;
      }

      txn.set(notificationRef, {
        'type': 'price_drop',
        'productId': productId,
        'title': 'Fiyat düştü',
        'body':
            'Takip ettiğin ürünün en düşük fiyatı ${previousLowest.toStringAsFixed(2)} → ${lowestPrice.toStringAsFixed(2)} oldu.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });

      txn.set(watchStateRef, {
        'lastNotifiedLowestPrice': lowestPrice,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  void _resetUserSubscriptions() {
    _watchlistSubscription?.cancel();
    _watchlistSubscription = null;
    for (final sub in _productSubscriptions.values) {
      sub.cancel();
    }
    _productSubscriptions.clear();
  }
}

