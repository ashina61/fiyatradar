import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class WatchlistItem {
  WatchlistItem({
    required this.productId,
    required this.productName,
    required this.targetPrice,
    required this.fcmToken,
    required this.createdAt,
  });

  final String productId;
  final String productName;
  final double targetPrice;
  final String? fcmToken;
  final DateTime? createdAt;

  factory WatchlistItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final createdAtRaw = data['createdAt'];
    return WatchlistItem(
      productId: (data['productId'] ?? doc.id).toString(),
      productName: (data['productName'] ?? '').toString(),
      targetPrice: (data['targetPrice'] as num?)?.toDouble() ?? 0,
      fcmToken: data['fcmToken']?.toString(),
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}

class WatchlistService {
  WatchlistService({FirebaseFirestore? firestore, FirebaseMessaging? messaging})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseMessaging _messaging;

  CollectionReference<Map<String, dynamic>> _watchlistRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('watchlist');

  Future<void> addToWatchlist(
    String userId,
    String productId,
    String productName,
    double currentPrice,
  ) async {
    final fcmToken = await _messaging.getToken();
    await _watchlistRef(userId).doc(productId).set({
      'productId': productId,
      'productName': productName,
      'targetPrice': currentPrice,
      'fcmToken': fcmToken,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeFromWatchlist(String userId, String productId) {
    return _watchlistRef(userId).doc(productId).delete();
  }

  Stream<bool> isWatchlisted(String userId, String productId) {
    return _watchlistRef(userId)
        .doc(productId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<WatchlistItem>> getWatchlist(String userId) {
    return _watchlistRef(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WatchlistItem.fromDoc)
              .toList(growable: false),
        );
  }
}
