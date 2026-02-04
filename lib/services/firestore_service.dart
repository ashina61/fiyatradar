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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.priceEntryCount.compareTo(a.priceEntryCount));
          return list.take(limit).toList();
        });
  }

  // Get recommended products (by view count)
  Stream<List<ProductModel>> getRecommendedProducts({int limit = 10}) {
    return _productsRef
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.viewCount.compareTo(a.viewCount));
          return list.take(limit).toList();
        });
  }

  // Get all products
  Stream<List<ProductModel>> getAllProducts() {
    return _productsRef
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ProductModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PriceModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<PriceModel?> getLatestPrice(String productId) async {
    final snapshot = await _pricesRef
        .where('productId', isEqualTo: productId)
        .get();

    final prices = snapshot.docs
        .map((doc) => PriceModel.fromFirestore(doc))
        .where((p) => p.isApproved)
        .toList();
    prices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return prices.isNotEmpty ? prices.first : null;
  }

  // Get latest prices across all products
  Stream<List<PriceModel>> getLatestPrices({int limit = 10}) {
    return _pricesRef
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PriceModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list.take(limit).toList();
        });
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

  Future<void> verifyPrice(String priceId, String voterId, bool isVerified) async {
    final field = isVerified ? 'verifiedCount' : 'unverifiedCount';
    await _pricesRef.doc(priceId).update({
      field: FieldValue.increment(1),
      'verifiedBy': FieldValue.arrayUnion([voterId]),
    });
    // Give the voter +5 points for validating
    await _usersRef.doc(voterId).update({
      'validations': FieldValue.increment(1),
      'points': FieldValue.increment(5),
    });
  }

  // Check if user already verified a price
  Future<bool> hasUserVerifiedPrice(String priceId, String userId) async {
    final doc = await _pricesRef.doc(priceId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    final verifiedBy = List<String>.from(data?['verifiedBy'] ?? []);
    return verifiedBy.contains(userId);
  }

  // Report a price
  Future<void> reportPrice(String priceId, String userId, String reason) async {
    await _firestore.collection('reports').add({
      'type': 'price',
      'targetId': priceId,
      'userId': userId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Report a comment
  Future<void> reportComment(String commentId, String userId, String reason) async {
    await _firestore.collection('reports').add({
      'type': 'comment',
      'targetId': commentId,
      'userId': userId,
      'reason': reason,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Pending prices for admin
  Stream<List<PriceModel>> getPendingPrices() {
    return _pricesRef
        .where('isPending', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PriceModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => CommentModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<String> addComment(CommentModel comment) async {
    final doc = await _commentsRef.add(comment.toFirestore());
    return doc.id;
  }

  Future<void> likeComment(String commentId, String userId) async {
    final doc = await _commentsRef.doc(commentId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final likedBy = List<String>.from(data?['likedBy'] ?? []);
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BannerModel.fromFirestore(doc))
              .where((banner) => banner.shouldShow)
              .toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        });
  }

  Stream<List<BannerModel>> getAllBanners() {
    return _bannersRef
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => BannerModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => a.order.compareTo(b.order));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
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
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs.toList();
          docs.sort((a, b) {
            final aTime = (a.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            final bTime = (b.data()['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
            return bTime.compareTo(aTime);
          });
          return docs.take(limit).map((doc) => doc.data()['query'] as String).toList();
        });
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

  // Categories
  CollectionReference get _categoriesRef => _firestore.collection('categories');

  Stream<List<Map<String, dynamic>>> getCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
          'iconName': data['iconName'] ?? 'category',
          'order': data['order'] ?? 0,
        };
      }).toList();
      list.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      return list;
    });
  }

  Future<String> addCategory(String name, String iconName) async {
    final doc = await _categoriesRef.add({
      'name': name,
      'iconName': iconName,
      'order': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  // Stores
  CollectionReference get _storesRef => _firestore.collection('stores');

  Stream<List<Map<String, dynamic>>> getStores() {
    return _storesRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? '',
        };
      }).toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return list;
    });
  }

  Future<String> addStore(String name) async {
    final doc = await _storesRef.add({
      'name': name,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> deleteStore(String storeId) async {
    await _storesRef.doc(storeId).delete();
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    await _productsRef.doc(productId).delete();
  }

  // Delete comment
  Future<void> deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }
}
