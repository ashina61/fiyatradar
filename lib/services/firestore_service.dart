import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/banner_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Products
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _pricesRef => _firestore.collection('prices');
  CollectionReference get _commentsRef => _firestore.collection('comments');
  CollectionReference get _notificationsRef => _firestore.collection('notifications');
  CollectionReference get _bannersRef => _firestore.collection('banners');
  CollectionReference get _usersRef => _firestore.collection('users');

  // Get trending products (most price entries)
  Stream<List<ProductModel>> getTrendingProducts({int limit = 10}) {
    return _productsRef
        .orderBy('priceEntryCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // Get recommended products (by view count)
  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _productsRef
        .orderBy('viewCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // Get all products
  Stream<List<ProductModel>> getAllProducts() {
    return _productsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    final queryLower = query.toLowerCase();
    final snapshot = await _productsRef.get();
    return snapshot.docs
        .map((doc) => ProductModel.fromFirestore(doc))
        .where((product) =>
            product.name.toLowerCase().contains(queryLower) ||
            product.brand.toLowerCase().contains(queryLower) ||
            (product.barcode?.contains(query) ?? false))
        .toList();
  }

  // Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromFirestore(doc);
    }
    return null;
  }

  // Increment view count
  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Add product
  Future<String> addProduct(ProductModel product) async {
    final doc = await _productsRef.add(product.toFirestore());
    return doc.id;
  }

  // Update product
  Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _productsRef.doc(productId).update(data);
  }

  // Prices
  Stream<List<PriceModel>> getPricesForProduct(String productId) {
    return _pricesRef
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceModel.fromFirestore(doc))
            .toList());
  }

  Future<PriceModel?> getLatestPrice(String productId) async {
    final snapshot = await _pricesRef
        .where('productId', isEqualTo: productId)
        .where('isApproved', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return PriceModel.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<String> addPrice(PriceModel price) async {
    final doc = await _pricesRef.add(price.toFirestore());

    // Update product's price entry count
    await _productsRef.doc(price.productId).update({
      'priceEntryCount': FieldValue.increment(1),
      'lastPrice': price.price,
      'lastStore': price.storeName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  Future<void> verifyPrice(String priceId, bool isVerified) async {
    final field = isVerified ? 'verifiedCount' : 'unverifiedCount';
    await _pricesRef.doc(priceId).update({
      field: FieldValue.increment(1),
    });
  }

  // Pending prices for admin
  Stream<List<PriceModel>> getPendingPrices() {
    return _pricesRef
        .where('isPending', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceModel.fromFirestore(doc))
            .toList());
  }

  Future<void> approvePrice(String priceId) async {
    await _pricesRef.doc(priceId).update({
      'isApproved': true,
      'isPending': false,
    });
  }

  Future<void> rejectPrice(String priceId) async {
    await _pricesRef.doc(priceId).update({
      'isApproved': false,
      'isPending': false,
    });
  }

  // Comments
  Stream<List<CommentModel>> getComments(String productId) {
    return _commentsRef
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }

  Future<String> addComment(CommentModel comment) async {
    final doc = await _commentsRef.add(comment.toFirestore());
    return doc.id;
  }

  Future<void> likeComment(String commentId, String userId) async {
    final doc = await _commentsRef.doc(commentId).get();
    if (doc.exists) {
      final likedBy = List<String>.from(doc.data() as Map<String, dynamic>?['likedBy'] ?? []);
      if (likedBy.contains(userId)) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }
      await _commentsRef.doc(commentId).update({
        'likedBy': likedBy,
        'likes': likedBy.length,
      });
    }
  }

  // Notifications
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _notificationsRef
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> addNotification(NotificationModel notification) async {
    await _notificationsRef.add(notification.toFirestore());
  }

  // Banners
  Stream<List<BannerModel>> getActiveBanners() {
    return _bannersRef
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .where((banner) => banner.shouldShow)
            .toList());
  }

  Stream<List<BannerModel>> getAllBanners() {
    return _bannersRef
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BannerModel.fromFirestore(doc))
            .toList());
  }

  Future<String> addBanner(BannerModel banner) async {
    final doc = await _bannersRef.add(banner.toFirestore());
    return doc.id;
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    await _bannersRef.doc(bannerId).update(data);
  }

  Future<void> deleteBanner(String bannerId) async {
    await _bannersRef.doc(bannerId).delete();
  }

  // Users (for admin)
  Stream<List<UserModel>> getAllUsers() {
    return _usersRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  Future<void> updateUserAdmin(String userId, bool isAdmin) async {
    await _usersRef.doc(userId).update({
      'isAdmin': isAdmin,
    });
  }

  // Search history
  Future<void> saveSearchHistory(String userId, String query) async {
    final doc = _usersRef.doc(userId).collection('searchHistory').doc();
    await doc.set({
      'query': query,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<String>> getSearchHistory(String userId, {int limit = 10}) {
    return _usersRef
        .doc(userId)
        .collection('searchHistory')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc.data()['query'] as String).toList());
  }

  Future<void> clearSearchHistory(String userId) async {
    final batch = _firestore.batch();
    final snapshot =
        await _usersRef.doc(userId).collection('searchHistory').get();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Saved products
  Stream<List<ProductModel>> getSavedProducts(List<String> productIds) {
    if (productIds.isEmpty) {
      return Stream.value([]);
    }
    return _productsRef
        .where(FieldPath.documentId, whereIn: productIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(doc))
            .toList());
  }
}
