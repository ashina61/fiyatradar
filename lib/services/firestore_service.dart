import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/brand_model.dart';
import '../models/store_model.dart';
import '../utils/constants.dart';
import '../models/banner_model.dart';
import '../models/user_model.dart';
import '../models/store_suggestion_model.dart';
import '../models/product_suggestion_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _productsRef => _firestore.collection('products');
  CollectionReference get _pricesRef => _firestore.collection('priceReports');
  CollectionReference get _commentsRef => _firestore.collection('comments');
  CollectionReference get _notificationsRef =>
      _firestore.collection('inAppNotifications');
  CollectionReference get _bannersRef => _firestore.collection('banners');
  CollectionReference get _usersRef => _firestore.collection('users');
  CollectionReference get _brandsRef => _firestore.collection('brands');
  CollectionReference get _storesRef => _firestore.collection('stores');
  CollectionReference get _storeSuggestionsRef =>
      _firestore.collection('storeSuggestions');
  CollectionReference get _productSuggestionsRef =>
      _firestore.collection('productSuggestions');
  DocumentReference get _maintenanceRef =>
      _firestore.collection('app_config').doc('maintenance');

  // =========================================================================
  // BRANDS
  // =========================================================================

  Stream<List<BrandModel>> getAllBrands() {
    return _brandsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => BrandModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    });
  }

  Future<String> addBrand(BrandModel brand) async {
    final doc = await _brandsRef.add(brand.toFirestore());
    return doc.id;
  }

  Future<void> updateBrand(String brandId, Map<String, dynamic> data) async {
    await _brandsRef.doc(brandId).update(data);
  }

  Future<void> deleteBrand(String brandId) async {
    await _brandsRef.doc(brandId).delete();
  }

  Future<BrandModel?> getBrandById(String brandId) async {
    final doc = await _brandsRef.doc(brandId).get();
    if (!doc.exists) return null;
    return BrandModel.fromFirestore(doc);
  }

  // =========================================================================
  // STORES (Subeler)
  // =========================================================================

  Stream<List<StoreModel>> getAllStoresStream() {
    return _storesRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Stream<List<StoreModel>> getActiveStores() {
    return _storesRef
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }


  Stream<List<StoreModel>> getNearbyActiveStoresStream() {
    return _storesRef
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .where((store) => !store.isOnline)
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Stream<List<StoreModel>> getOnlineActiveStoresStream() {
    return _storesRef
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .where((store) => store.isOnline)
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Future<List<StoreModel>> getNearbyActiveStores({
    required double userLat,
    required double userLng,
    double maxDistanceMeters = 2000,
  }) async {
    final snapshot = await _storesRef.where('status', isEqualTo: 'active').get();
    final stores = snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
    stores.sort((a, b) {
      final aDistance = _distanceInMeters(userLat, userLng, a.lat, a.lng);
      final bDistance = _distanceInMeters(userLat, userLng, b.lat, b.lng);
      return aDistance.compareTo(bDistance);
    });
    return stores
        .where((store) =>
            !store.isOnline &&
            store.lat != 0 &&
            store.lng != 0 &&
            _distanceInMeters(userLat, userLng, store.lat, store.lng) <=
                maxDistanceMeters)
        .toList();
  }

  Stream<List<StoreSuggestionModel>> getPendingStoreSuggestions() {
    return _storeSuggestionsRef
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreSuggestionModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<String> addStore(StoreModel store) async {
    final doc = await _storesRef.add(store.toFirestore());
    return doc.id;
  }

  Future<String> addStoreSuggestion({
    required String displayName,
    required double lat,
    required double lng,
    String city = '',
    String district = '',
    String neighborhood = '',
  }) async {
    final doc = await _storeSuggestionsRef.add({
      'displayName': displayName,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'lat': lat,
      'lng': lng,
      'status': 'pending',
      'resolvedStoreId': null,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> approveStoreSuggestion(String suggestionId) async {
    final suggestionDoc = await _storeSuggestionsRef.doc(suggestionId).get();
    if (!suggestionDoc.exists) return;
    final suggestion = StoreSuggestionModel.fromFirestore(suggestionDoc);

    final storeRef = await _storesRef.add({
      'displayName': suggestion.displayName,
      'name': suggestion.displayName,
      'city': suggestion.city,
      'district': suggestion.district,
      'neighborhood': suggestion.neighborhood,
      'lat': suggestion.lat,
      'lng': suggestion.lng,
      'status': 'active',
      'type': StoreType.local.name,
      'isOnline': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _storeSuggestionsRef.doc(suggestionId).update({
      'status': 'approved',
      'resolvedStoreId': storeRef.id,
    });
  }

  Future<void> mergeStoreSuggestion({
    required String suggestionId,
    required String targetStoreId,
  }) async {
    await _storeSuggestionsRef.doc(suggestionId).update({
      'status': 'merged',
      'resolvedStoreId': targetStoreId,
    });
  }

  Future<void> rejectStoreSuggestion(String suggestionId) async {
    await _storeSuggestionsRef.doc(suggestionId).update({
      'status': 'rejected',
    });
  }

  Future<void> updateStore(String storeId, Map<String, dynamic> data) async {
    await _storesRef.doc(storeId).update(data);
  }

  Future<void> approveStore(String storeId) async {
    await _storesRef.doc(storeId).update({'status': 'active'});
  }

  Future<void> hideStore(String storeId) async {
    await _storesRef.doc(storeId).update({'status': 'hidden'});
  }

  Future<void> deleteStore(String storeId) async {
    await _storesRef.doc(storeId).delete();
  }

  Future<StoreModel?> getStoreById(String storeId) async {
    final doc = await _storesRef.doc(storeId).get();
    if (!doc.exists) return null;
    return StoreModel.fromFirestore(doc);
  }

  /// Merge two stores: move all priceReports from sourceId to targetId, then delete source
  Future<void> mergeStores(String sourceId, String targetId) async {
    final targetStore = await getStoreById(targetId);
    if (targetStore == null) return;

    // Update all prices referencing sourceId
    final priceSnapshot = await _pricesRef
        .where('storeId', isEqualTo: sourceId)
        .get();

    final batch = _firestore.batch();
    for (final doc in priceSnapshot.docs) {
      batch.update(doc.reference, {
        'storeId': targetId,
        'branchStoreId': targetId,
        'storeName': targetStore.displayName,
        'chainId': targetStore.brandId,
      });
    }
    batch.delete(_storesRef.doc(sourceId));
    await batch.commit();
  }

  // Legacy store methods (for backward compat during migration)
  Stream<List<Map<String, dynamic>>> getStores() {
    return _storesRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['displayName'] ?? data['name'] ?? '',
        };
      }).toList();
      list.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return list;
    });
  }

  Future<String> addStoreLegacy(String name) async {
    final doc = await _storesRef.add({
      'displayName': name,
      'name': name,
      'city': '',
      'district': '',
      'neighborhood': '',
      'lat': 0.0,
      'lng': 0.0,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // =========================================================================
  // PRODUCTS
  // =========================================================================

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

  // Maintenance mode
  Stream<bool> getMaintenanceMode() {
    return _maintenanceRef.snapshots().map((doc) {
      if (!doc.exists) return false;
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return data['enabled'] as bool? ?? false;
    });
  }

  Future<void> setMaintenanceMode(bool enabled) async {
    await _maintenanceRef.set({
      'enabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

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

  Future<ProductModel?> getProduct(String productId) async {
    final doc = await _productsRef.doc(productId).get();
    if (doc.exists) {
      return ProductModel.fromFirestore(doc);
    }
    return null;
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

  Future<List<String>> getCampaignProductIdsForBanner(String bannerId) async {
    final sub = await _bannersRef.doc(bannerId).collection('campaignProducts').get();
    return sub.docs
        .map((doc) => (doc.data()['productId'] ?? doc.id).toString())
        .where((id) => id.trim().isNotEmpty)
        .toList();
  }

  Future<void> incrementViewCount(String productId) async {
    await _productsRef.doc(productId).update({
      'viewCount': FieldValue.increment(1),
    });
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

  // =========================================================================
  // PRICES
  // =========================================================================

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
    return addPriceReport(price);
  }

  Future<String> addPriceReport(PriceModel price) async {
    final productDoc = await _productsRef.doc(price.productId).get();
    final productData = productDoc.data() as Map<String, dynamic>?;
    final oldPrice = (productData?['lastPrice'] as num?)?.toDouble();

    final doc = await _pricesRef.add(price.toFirestore());

    // Update product's price entry count
    await _productsRef.doc(price.productId).update({
      'priceEntryCount': FieldValue.increment(1),
      'lastPrice': price.price,
      'lastStore': price.storeName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final notificationCount = await _createFollowerNotifications(
      productId: price.productId,
      priceReporterId: price.userId,
      productName: productData?['name']?.toString() ?? price.productName ?? 'Urun',
      oldPrice: oldPrice,
      newPrice: price.price,
      storeName: price.storeName,
    );

    // ignore: avoid_print
    print('[Notifications] Product ${price.productId}: $notificationCount bildirim yazildi');

    return doc.id;
  }

  Future<int> _createFollowerNotifications({
    required String productId,
    required String priceReporterId,
    required String productName,
    required double? oldPrice,
    required double newPrice,
    String? storeName,
  }) async {
    final isDrop = oldPrice != null && newPrice < oldPrice;
    final percentChange =
        oldPrice != null && oldPrice > 0 ? ((newPrice - oldPrice) / oldPrice) * 100 : null;

    final followedSnapshot = await _firestore
        .collectionGroup('followedProducts')
        .where(FieldPath.documentId, isEqualTo: productId)
        .get();

    final batch = _firestore.batch();
    var notificationCount = 0;

    for (final followDoc in followedSnapshot.docs) {
      final userRef = followDoc.reference.parent.parent;
      final uid = userRef?.id;
      if (uid == null || uid.isEmpty || uid == priceReporterId) continue;

      final followData = followDoc.data();
      final notifyOnNewPrice = followData['notifyOnNewPrice'] == true;
      final notifyOnPriceDrop = followData['notifyOnPriceDrop'] == true;

      if (notifyOnNewPrice) {
        final ref = _notificationsRef.doc();
        batch.set(ref, {
          'id': ref.id,
          'userId': uid,
          'type': 'new_price',
          'productId': productId,
          'title': '$productName icin yeni fiyat',
          'body': storeName == null || storeName.isEmpty
              ? 'Yeni fiyat girildi: ${newPrice.toStringAsFixed(2)}₺'
              : '$storeName magazasinda yeni fiyat: ${newPrice.toStringAsFixed(2)}₺',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'meta': {
            'oldPrice': oldPrice,
            'newPrice': newPrice,
            'storeName': storeName,
            'percentChange': percentChange,
          },
        });
        notificationCount += 1;
      }

      if (isDrop && notifyOnPriceDrop) {
        final ref = _notificationsRef.doc();
        batch.set(ref, {
          'id': ref.id,
          'userId': uid,
          'type': 'price_drop',
          'productId': productId,
          'title': '$productName fiyat dustu',
          'body': '${oldPrice!.toStringAsFixed(2)}₺ → ${newPrice.toStringAsFixed(2)}₺',
          'createdAt': FieldValue.serverTimestamp(),
          'isRead': false,
          'meta': {
            'oldPrice': oldPrice,
            'newPrice': newPrice,
            'storeName': storeName,
            'percentChange': percentChange,
          },
        });
        notificationCount += 1;
      }
    }

    if (notificationCount > 0) {
      await batch.commit();
    }

    return notificationCount;
  }

  Future<void> setFollowedProduct({
    required String userId,
    required String productId,
    required bool notifyOnNewPrice,
    required bool notifyOnPriceDrop,
  }) async {
    final docRef = _usersRef.doc(userId).collection('followedProducts').doc(productId);
    if (!notifyOnNewPrice && !notifyOnPriceDrop) {
      await docRef.delete();
      return;
    }

    await docRef.set({
      'notifyOnNewPrice': notifyOnNewPrice,
      'notifyOnPriceDrop': notifyOnPriceDrop,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> followedProductStream({
    required String userId,
    required String productId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('followedProducts')
        .doc(productId)
        .snapshots();
  }

  Future<String> addProductSuggestion({
    required String name,
    String? barcode,
    String? category,
    String? brand,
    String? photoUrl,
    required String userId,
  }) async {
    final doc = await _productSuggestionsRef.add({
      'name': name,
      'barcode': barcode,
      'category': category,
      'brand': brand,
      'photoUrl': photoUrl,
      'imageUrl': photoUrl,
      'userId': userId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Stream<List<ProductSuggestionModel>> getPendingProductSuggestions() {
    return _productSuggestionsRef
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => ProductSuggestionModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> approveProductSuggestion(String suggestionId) async {
    final suggestionDoc = await _productSuggestionsRef.doc(suggestionId).get();
    if (!suggestionDoc.exists) return;
    final data = suggestionDoc.data() as Map<String, dynamic>? ?? {};
    final name = (data['name'] ?? '').toString().trim();
    if (name.isEmpty) return;

    final category = (data['category'] ?? '').toString();
    final brand = (data['brand'] ?? '').toString();
    final imageUrl = ((data['imageUrl'] ?? data['photoUrl']) ?? '').toString();
    final productRef = await _productsRef.add({
      'name': name,
      'brand': brand,
      'category': category,
      'categories': category.isEmpty ? <String>[] : <String>[category],
      'barcode': data['barcode'],
      'imageUrl': imageUrl.isEmpty ? null : imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'priceEntryCount': 0,
      'viewCount': 0,
      'isActive': true,
    });

    await _productSuggestionsRef.doc(suggestionId).update({
      'status': 'approved',
      'resolvedProductId': productRef.id,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectProductSuggestion(String suggestionId) async {
    await _productSuggestionsRef.doc(suggestionId).update({
      'status': 'rejected',
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  double _distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            (sin(dLon / 2) * sin(dLon / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * 0.017453292519943295;

  Future<void> verifyPrice(String priceId, String voterId, bool isVerified) async {
    final field = isVerified ? 'verifiedCount' : 'unverifiedCount';
    await _pricesRef.doc(priceId).update({
      field: FieldValue.increment(1),
      'verifiedBy': FieldValue.arrayUnion([voterId]),
    });
    await _usersRef.doc(voterId).update({
      'validations': FieldValue.increment(1),
      'points': FieldValue.increment(AppConstants.pointsForValidation),
    });
  }

  /// Upvote a price report
  Future<void> upVotePrice(String priceId, String voterId) async {
    await _pricesRef.doc(priceId).update({
      'upVotes': FieldValue.increment(1),
      'score': FieldValue.increment(1),
      'votedBy': FieldValue.arrayUnion([voterId]),
    });
  }

  /// Downvote a price report
  Future<void> downVotePrice(String priceId, String voterId) async {
    await _pricesRef.doc(priceId).update({
      'downVotes': FieldValue.increment(1),
      'score': FieldValue.increment(-1),
      'votedBy': FieldValue.arrayUnion([voterId]),
    });

    // Auto-hide if score drops below threshold
    final doc = await _pricesRef.doc(priceId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final score = (data['score'] as num?)?.toDouble() ?? 0;
      if (score <= AppConstants.autoHideScoreThreshold) {
        await _pricesRef.doc(priceId).update({
          'isApproved': false,
          'isPending': false,
        });
      }
    }
  }

  /// Check if user already voted on a price
  Future<bool> hasUserVotedPrice(String priceId, String userId) async {
    final doc = await _pricesRef.doc(priceId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    final votedBy = List<String>.from(data?['votedBy'] ?? []);
    return votedBy.contains(userId);
  }

  Future<bool> hasUserVerifiedPrice(String priceId, String userId) async {
    final doc = await _pricesRef.doc(priceId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    final verifiedBy = List<String>.from(data?['verifiedBy'] ?? []);
    return verifiedBy.contains(userId);
  }

  Future<void> reportPrice({
    required String priceId,
    required String userId,
    required String reason,
    String? contextId,
  }) async {
    await _firestore.collection('reports').add({
      'targetType': 'priceEntry',
      'targetId': priceId,
      'contextId': contextId,
      'reason': reason,
      'reporterUserId': userId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedBy': null,
      'resolvedAt': null,
    });
    await _usersRef.doc(userId).update({
      'points': FieldValue.increment(AppConstants.pointsForReportPrice),
    });
  }

  Future<void> reportComment({
    required String commentId,
    required String userId,
    required String reason,
    String? contextId,
  }) async {
    await _firestore.collection('reports').add({
      'targetType': 'comment',
      'targetId': commentId,
      'contextId': contextId,
      'reason': reason,
      'reporterUserId': userId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedBy': null,
      'resolvedAt': null,
    });
  }

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

  // =========================================================================
  // COMMENTS
  // =========================================================================

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
    await _usersRef.doc(comment.userId).update({
      'points': FieldValue.increment(AppConstants.pointsForComment),
    });
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

  Future<void> deleteComment(String commentId) async {
    await _commentsRef.doc(commentId).delete();
  }

  // =========================================================================
  // NOTIFICATIONS
  // =========================================================================

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

  Future<void> deleteNotification(String notificationId) async {
    await _notificationsRef.doc(notificationId).delete();
  }

  // =========================================================================
  // BANNERS
  // =========================================================================

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

  // =========================================================================
  // USERS (admin)
  // =========================================================================

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

  Future<void> updateUserFcmToken(String userId, String token) async {
    await _usersRef.doc(userId).update({
      'fcmToken': token,
      'fcmUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).update(data);
  }

  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersRef.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  // =========================================================================
  // SEARCH HISTORY
  // =========================================================================

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

  // =========================================================================
  // SAVED PRODUCTS
  // =========================================================================

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

  // =========================================================================
  // CATEGORIES
  // =========================================================================

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
          'imageUrl': data['imageUrl'],
          'imagePath': data['imagePath'],
        };
      }).toList();
      list.sort((a, b) => (a['order'] as int).compareTo(b['order'] as int));
      return list;
    });
  }

  Future<String> addCategory(String name, String iconName, {String? imageUrl, String? imagePath}) async {
    final doc = await _categoriesRef.add({
      'name': name,
      'iconName': iconName,
      'order': 0,
      'createdAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imagePath != null) 'imagePath': imagePath,
    });
    return doc.id;
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    await _categoriesRef.doc(categoryId).update(data);
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }

  // =========================================================================
  // BASKET
  // =========================================================================

  CollectionReference<Map<String, dynamic>> _basketRef(String userId) {
    return _usersRef.doc(userId).collection('basketItems');
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
  }) async {
    await _basketRef(userId).doc(productId).set({
      'productId': productId,
      'quantity': quantity,
      'addedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> removeBasketItem({
    required String userId,
    required String productId,
  }) async {
    await _basketRef(userId).doc(productId).delete();
  }

  // =========================================================================
  // REPORTS
  // =========================================================================

  CollectionReference get _reportsRef => _firestore.collection('reports');

  Stream<List<Map<String, dynamic>>> getReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        return {
          'id': doc.id,
          'targetType': data['targetType'] ?? data['type'] ?? '',
          'targetId': data['targetId'] ?? '',
          'contextId': data['contextId'],
          'reporterUserId': data['reporterUserId'] ?? data['userId'] ?? '',
          'reason': data['reason'] ?? '',
          'status': status == 'dismissed' ? 'rejected' : status,
          'resolutionNote': data['resolutionNote'],
          'resolvedBy': data['resolvedBy'],
          'resolvedAt': (data['resolvedAt'] as Timestamp?)?.toDate(),
          'createdAt': (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
      list.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
      return list;
    });
  }

  Future<void> updateReportStatus(
    String reportId,
    String status, {
    String? resolvedBy,
    String? resolutionNote,
  }) async {
    await _reportsRef.doc(reportId).update({
      'status': status,
      if (resolvedBy != null) 'resolvedBy': resolvedBy,
      if (status != 'pending') 'resolvedAt': FieldValue.serverTimestamp(),
      if (resolutionNote != null) 'resolutionNote': resolutionNote,
    });
  }

  Future<void> deleteReport(String reportId) async {
    await _reportsRef.doc(reportId).delete();
  }

  Future<CommentModel?> getCommentById(String commentId) async {
    final doc = await _commentsRef.doc(commentId).get();
    if (!doc.exists) return null;
    return CommentModel.fromFirestore(doc);
  }

  Future<PriceModel?> getPriceById(String priceId) async {
    final doc = await _pricesRef.doc(priceId).get();
    if (!doc.exists) return null;
    return PriceModel.fromFirestore(doc);
  }

  Future<List<PriceModel>> getPricesForProductIds(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    final results = <PriceModel>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < productIds.length; i += 10) {
      chunks.add(productIds.sublist(
        i,
        i + 10 > productIds.length ? productIds.length : i + 10,
      ));
    }
    for (final chunk in chunks) {
      final snapshot = await _pricesRef
          .where('productId', whereIn: chunk)
          .get();
      results.addAll(snapshot.docs.map((doc) => PriceModel.fromFirestore(doc)));
    }
    return results;
  }

  Future<List<PriceModel>> getPricesForProductKeys(List<String> productKeys) async {
    if (productKeys.isEmpty) return [];
    final results = <PriceModel>[];
    final chunks = <List<String>>[];
    for (var i = 0; i < productKeys.length; i += 10) {
      chunks.add(productKeys.sublist(
        i,
        i + 10 > productKeys.length ? productKeys.length : i + 10,
      ));
    }
    for (final chunk in chunks) {
      final snapshot = await _pricesRef.where('productId', whereIn: chunk).get();
      results.addAll(snapshot.docs.map((doc) => PriceModel.fromFirestore(doc)));
    }
    return results;
  }
}
