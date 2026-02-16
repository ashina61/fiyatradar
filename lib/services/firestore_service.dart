import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../models/price_model.dart';
import '../models/comment_model.dart';
import '../models/notification_model.dart';
import '../models/brand_model.dart';
import '../models/store_model.dart';
import '../utils/constants.dart';
import '../models/banner_model.dart';
import '../models/user_model.dart';
import '../models/campaign_basket_model.dart';
import '../models/store_suggestion_model.dart';
import '../models/product_suggestion_model.dart';
import '../models/category_model.dart';
import '../models/actual_item_model.dart';
import '../models/actual_model.dart';
import '../utils/safe_query_builder.dart';
import '../services/storage_service.dart';
import 'points_service.dart';

class DuplicatePriceException implements Exception {
  const DuplicatePriceException(this.message);
  final String message;

  @override
  String toString() => message;
}


class AlreadyVotedException implements Exception {
  const AlreadyVotedException([this.message = 'Zaten oy verdin']);
  final String message;

  @override
  String toString() => message;
}

enum PriceVoteStatus { newVote, alreadyVoted, selfVoteBlocked, ignored }

class PriceVoteResult {
  const PriceVoteResult(
    this.status, {
    this.upCount,
    this.downCount,
    this.score,
  });

  final PriceVoteStatus status;
  final int? upCount;
  final int? downCount;
  final int? score;

  bool get shouldAward => status == PriceVoteStatus.newVote;
}

class PriceStatusMigrationResult {
  const PriceStatusMigrationResult({
    required this.updatedCount,
    required this.scannedCount,
  });

  final int updatedCount;
  final int scannedCount;
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PointsService _pointsService = PointsService();
  final Set<String> _offFetchInFlight = <String>{};

  void _logFirestoreQueryError(
    String context,
    Object error,
    StackTrace stackTrace,
  ) {
    if (!kDebugMode) return;
    // Native logcat tag'leri ile hizali debug format.
    debugPrint('E/FLTFirestoreMsgCodec($context): $error');
    debugPrint('W/FirebaseFirestore($context): $error');
    debugPrintStack(stackTrace: stackTrace, label: 'FIRESTORE QUERY STACK ($context)');
  }

  // Collection references
  CollectionReference<Map<String, dynamic>> get _productsRef => _firestore.collection('products');
  CollectionReference<Map<String, dynamic>> get _pricesRef => _firestore.collection('priceReports');
  CollectionReference<Map<String, dynamic>> get _commentsRef => _firestore.collection('comments');
  CollectionReference<Map<String, dynamic>> get _notificationsRef =>
      _firestore.collection('inAppNotifications');
  CollectionReference<Map<String, dynamic>> get _legacyNotificationsRef =>
      _firestore.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _bannersRef => _firestore.collection('banners');
  CollectionReference<Map<String, dynamic>> get _campaignBasketsRef => _firestore.collection('campaignBaskets');
  CollectionReference<Map<String, dynamic>> get _usersRef => _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _brandsRef => _firestore.collection('brands');
  CollectionReference<Map<String, dynamic>> get _storesRef => _firestore.collection('stores');
  CollectionReference<Map<String, dynamic>> get _storeSuggestionsRef =>
      _firestore.collection('storeSuggestions');
  CollectionReference<Map<String, dynamic>> get _productSuggestionsRef =>
      _firestore.collection('productSuggestions');
  CollectionReference<Map<String, dynamic>> get _priceDedupeRef => _firestore.collection('price_dedupes');
  CollectionReference<Map<String, dynamic>> get _weeklyDealsRef => _firestore.collection('weekly_deals');
  CollectionReference<Map<String, dynamic>> get _actualsRef => _firestore.collection('actuals');
  CollectionReference<Map<String, dynamic>> get _stockReportsRef => _firestore.collection('stock_reports');
  CollectionReference<Map<String, dynamic>> get _stockValidationRef => _firestore.collection('stock_validation');
  DocumentReference<Map<String, dynamic>> get _maintenanceRef =>
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


  Stream<List<BrandModel>> getActiveBrands() {
    final query = SafeQueryBuilder.safeWhere(_brandsRef, 'isActive', true, expectedType: bool);
    return query.snapshots().map((snapshot) {
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
    final query = SafeQueryBuilder.safeWhere(_storesRef, 'status', 'active', expectedType: String);
    return query
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
        .snapshots()
        .handleError((error, stackTrace) {
      debugPrint('[AddPrice] nearby branch query error: $error');
      if (error is FirebaseException) {
        debugPrint('[AddPrice] nearby branch Firestore message: ${error.message}');
      }
      if (stackTrace is StackTrace) {
        debugPrintStack(stackTrace: stackTrace);
      }
    })
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .where((store) => store.status == StoreStatus.active && !store.isOnline)
          .toList();
      list.sort((a, b) => a.displayName.compareTo(b.displayName));
      return list;
    });
  }

  Stream<List<StoreModel>> getOnlineActiveStoresStream() {
    return _storesRef
        .snapshots()
        .handleError((error, stackTrace) {
      debugPrint('[AddPrice] online branch query error: $error');
      if (error is FirebaseException) {
        debugPrint('[AddPrice] online branch Firestore message: ${error.message}');
      }
      if (stackTrace is StackTrace) {
        debugPrintStack(stackTrace: stackTrace);
      }
    })
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .where((store) => store.status == StoreStatus.active && store.isOnline)
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
    final query = SafeQueryBuilder.safeWhere(_storesRef, 'status', 'active', expectedType: String);
    final snapshot = await query.get();
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
    final query = SafeQueryBuilder.safeWhere(_storeSuggestionsRef, 'status', 'pending', expectedType: String);
    return query
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
    final priceQuery = SafeQueryBuilder.safeWhere(_pricesRef, 'storeId', sourceId, expectedType: String);
    final priceSnapshot = await priceQuery.get();

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
        final raw = doc.data();
        final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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
      final raw = doc.data();
      final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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
          for (final product in list) {
            _ensureOpenFoodFactsImage(product);
          }
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
      final product = ProductModel.fromFirestore(doc);
      await _ensureOpenFoodFactsImage(product);
      return product;
    }
    return null;
  }


  Future<void> _ensureOpenFoodFactsImage(ProductModel product) async {
    if ((product.effectiveImage ?? '').isNotEmpty) return;
    final barcode = product.barcode?.trim() ?? '';
    if (barcode.isEmpty) return;
    if (_offFetchInFlight.contains(product.id)) return;
    _offFetchInFlight.add(product.id);

    try {
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v2/product/$barcode.json');
      final response = await http.get(uri, headers: const {
        'User-Agent': 'FiyatRadar/1.0 (image-fallback)',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final productData = body['product'] as Map<String, dynamic>?;
      final imageFront = (productData?['image_front_url'] ?? '').toString();
      if (imageFront.isEmpty) return;
      await _productsRef.doc(product.id).set({
        'imageUrl': imageFront,
        'mainImage': imageFront,
        'imageSource': 'openfoodfacts',
        'imageApproved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Sessizce gec.
    } finally {
      _offFetchInFlight.remove(product.id);
    }
  }

  Future<Map<String, dynamic>> createAiPackshot({
    required ProductModel product,
    required StorageService storageService,
  }) async {
    final prompt = 'Ultra realistic Turkish grocery store packshot, front facing product, clean white background, soft supermarket lighting, realistic packaging, no watermark, high detail commercial food photography. Product: ${product.brand} ${product.name} Turkey packaging';
    final uri = Uri.parse('https://image.pollinations.ai/prompt/${Uri.encodeComponent(prompt)}');
    final response = await http.get(uri).timeout(const Duration(seconds: 40));
    if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
      throw Exception('AI packshot olusturulamadi.');
    }

    final urls = await storageService.uploadPackshotVariants(
      productId: product.id,
      imageBytes: response.bodyBytes,
    );

    final payload = {
      'imageThumbUrl': urls['imageThumbUrl'],
      'imageMediumUrl': urls['imageMediumUrl'],
      'imageUrl': urls['imageMediumUrl'],
      'mainImage': urls['imageThumbUrl'],
      'imageSource': 'ai_packshot',
      'aiGenerated': true,
      'aiPrompt': prompt,
      'imageApproved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await updateProduct(product.id, payload);
    return payload;
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


  Future<CampaignBasketModel?> getCampaignById(String id) async {
    if (id.trim().isEmpty) return null;
    final doc = await _campaignBasketsRef.doc(id).get();
    if (!doc.exists) return null;
    return CampaignBasketModel.fromFirestore(doc);
  }

  Stream<List<CampaignBasketModel>> getAllCampaigns() {
    return _campaignBasketsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CampaignBasketModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aOrder = a.sortOrder ?? 999999;
        final bOrder = b.sortOrder ?? 999999;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Stream<List<CampaignBasketModel>> getActiveCampaigns() {
    final query = SafeQueryBuilder.safeWhere(_campaignBasketsRef, 'isActive', true, expectedType: bool);
    return query
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => CampaignBasketModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aOrder = a.sortOrder ?? 999999;
        final bOrder = b.sortOrder ?? 999999;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return b.createdAt.compareTo(a.createdAt);
      });
      return list;
    });
  }

  Future<String> addCampaign(CampaignBasketModel campaign) async {
    final doc = await _campaignBasketsRef.add({
      ...campaign.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateCampaign(String id, Map<String, dynamic> data) async {
    await _campaignBasketsRef.doc(id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCampaign(String id) async {
    await _campaignBasketsRef.doc(id).delete();
  }

  @Deprecated('Use getCampaignById')
  Future<Map<String, dynamic>?> getCampaignBasket(String basketId) async {
    final model = await getCampaignById(basketId);
    if (model == null) return null;
    return model.toFirestore();
  }

  Future<List<ProductModel>> getCampaignBasketProducts(String basketId) async {
    final campaign = await getCampaignById(basketId);
    if (campaign == null || campaign.itemProductIds.isEmpty) return const [];
    return getProductsByIds(campaign.itemProductIds);
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
    var query = SafeQueryBuilder.safeWhere(_pricesRef, 'productId', productId, expectedType: String);
    query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
    return query
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => PriceModel.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }



  Future<PriceModel?> getLatestPriceForStore({
    required String productId,
    required String branchStoreId,
  }) async {
    try {
      var query = SafeQueryBuilder.safeWhere(_pricesRef, 'productId', productId, expectedType: String);
      query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
      final snapshot = await query.get();

      final prices = snapshot.docs
          .map((doc) => PriceModel.fromFirestore(doc))
          .where((price) => price.branchStoreId == branchStoreId)
          .toList()
        ..sort((a, b) => b.reportedAt.compareTo(a.reportedAt));
      return prices.isEmpty ? null : prices.first;
    } on FirebaseException catch (e, st) {
      _logFirestoreQueryError('getLatestPriceForStore', e, st);
      return null;
    } catch (e, st) {
      _logFirestoreQueryError('getLatestPriceForStore', e, st);
      return null;
    }
  }

  Future<PriceModel?> getLatestPrice(String productId) async {
    var query = SafeQueryBuilder.safeWhere(_pricesRef, 'productId', productId, expectedType: String);
    query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
    final snapshot = await query.get();

    final prices = snapshot.docs
        .map((doc) => PriceModel.fromFirestore(doc))
        .toList();
    prices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return prices.isNotEmpty ? prices.first : null;
  }

  Stream<List<PriceModel>> getLatestPrices({int limit = 10}) {
    var query = SafeQueryBuilder.safeWhere(_pricesRef, 'status', 'active', expectedType: String);
    return query
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

  String _priceDayKey(DateTime date) {
    final localDate = date.toLocal();
    final m = localDate.month.toString().padLeft(2, '0');
    final d = localDate.day.toString().padLeft(2, '0');
    return '${localDate.year}$m$d';
  }

  String _buildPriceDedupeKey({
    required String productId,
    required String branchStoreId,
    required double price,
    required DateTime reportedAt,
  }) {
    return '$productId|$branchStoreId|${price.toStringAsFixed(2)}|${_priceDayKey(reportedAt)}';
  }

  Future<String> addPriceReport(PriceModel price) async {
    final productDoc = await _productsRef.doc(price.productId).get();
    final productRaw = productDoc.data();
    final productData = productRaw is Map<String, dynamic> ? Map<String, dynamic>.from(productRaw) : null;
    final oldPrice = (productData?['lastPrice'] as num?)?.toDouble();
    final dedupeKey = _buildPriceDedupeKey(
      productId: price.productId,
      branchStoreId: price.branchStoreId,
      price: price.price,
      reportedAt: price.reportedAt,
    );
    final dayKey = _priceDayKey(price.reportedAt);

    final priceRef = _pricesRef.doc();
    final priceEntryRef = _firestore.collection('price_entries').doc(priceRef.id);
    final dedupeRef = _priceDedupeRef.doc(dedupeKey);

    await _firestore.runTransaction((txn) async {
      final dedupeDoc = await txn.get(dedupeRef);
      if (dedupeDoc.exists) {
        throw const DuplicatePriceException('Aynı fiyat zaten girilmiş.');
      }
      final payload = price.copyWith(id: priceRef.id, dedupeKey: dedupeKey).toFirestore();
      payload['createdByUid'] = price.userId;
      payload['dedupeKey'] = dedupeKey;
      payload['id'] = priceRef.id;
      payload['verificationStatus'] = payload['verificationStatus'] ?? 'unverified';
      txn.set(priceRef, payload);
      txn.set(priceEntryRef, {
        'productId': price.productId,
        'storeId': price.chainId,
        'branchId': price.branchStoreId,
        'price': price.price,
        'createdAt': FieldValue.serverTimestamp(),
        'createdByUid': price.userId,
        'createdByName': price.userName,
        'createdByTrustScore': price.addedByTrustScoreSnapshot,
        'status': 'active',
        'verification': {
          'upCount': 0,
          'downCount': 0,
          'score': 0,
          'userVotes': <String, String>{},
          'updatedAt': FieldValue.serverTimestamp(),
        },
      });
      txn.set(dedupeRef, {
        'productId': price.productId,
        'branchStoreId': price.branchStoreId,
        'price': price.price,
        'day': dayKey,
        'createdByUid': price.userId,
        'priceReportId': priceRef.id,
        'dedupeKey': dedupeKey,
        'createdAt': FieldValue.serverTimestamp(),
      });
      txn.update(_productsRef.doc(price.productId), {
        'priceEntryCount': FieldValue.increment(1),
        'lastPrice': price.price,
        'lastStore': price.storeName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    var notificationCount = 0;
    try {
      notificationCount = await _createFollowerNotifications(
        productId: price.productId,
        priceReporterId: price.userId,
        productName: productData?['name']?.toString() ?? price.productName ?? 'Urun',
        oldPrice: oldPrice,
        newPrice: price.price,
        storeName: price.storeName,
      );
    } on FirebaseException catch (e, st) {
      _logFirestoreQueryError('addPriceReport/_createFollowerNotifications', e, st);
    } catch (e, st) {
      _logFirestoreQueryError('addPriceReport/_createFollowerNotifications', e, st);
    }

    print('[Notifications] Product ${price.productId}: $notificationCount bildirim yazildi');

    try {
      await _pointsService.awardEvent(
        uid: price.userId,
        eventType: 'price_add',
        meta: {
          'productId': price.productId,
          'storeId': price.chainId,
          'branchId': price.branchStoreId,
          'priceEntryId': priceRef.id,
        },
      );
      await _pointsService.markReferralFirstContribution(price.userId);
    } catch (e, st) {
      _logFirestoreQueryError('addPriceReport/pointsAward', e, st);
    }

    return priceRef.id;
  }

  Future<int> _createFollowerNotifications({
    required String productId,
    required String priceReporterId,
    required String productName,
    required double? oldPrice,
    required double newPrice,
    String? storeName,
  }) async {
    if (productId.trim().isEmpty) {
      if (kDebugMode) {
        debugPrint('E/FLTFirestoreMsgCodec(_createFollowerNotifications): productId bos, query atlandi');
      }
      return 0;
    }

    final isDrop = oldPrice != null && newPrice < oldPrice;
    final percentChange =
        oldPrice != null && oldPrice > 0 ? ((newPrice - oldPrice) / oldPrice) * 100 : null;

    final followedSnapshot = await SafeQueryBuilder.safeWhere(
      _firestore.collectionGroup('followedProducts'),
      FieldPath.documentId,
      productId.trim(), // Query argumanini primitive + trim'li gonder.
      expectedType: String,
    ).get();

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
    final query = SafeQueryBuilder.safeWhere(_productSuggestionsRef, 'status', 'pending', expectedType: String);
    return query
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
    final raw = suggestionDoc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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

  Future<PriceVoteResult> voteOnPrice({
    required String priceId,
    required String priceOwnerUid,
    required int vote,
    required String voterUid,
  }) async {
    if (vote != 1 && vote != -1) {
      return const PriceVoteResult(PriceVoteStatus.ignored);
    }

    try {
      final result = await _firestore.runTransaction<PriceVoteResult>((txn) async {
        final priceRef = _pricesRef.doc(priceId);
        final voteRef = priceRef.collection('verifications').doc(voterUid);
        final voterRef = _usersRef.doc(voterUid);

        final priceSnap = await txn.get(priceRef);
        if (!priceSnap.exists) return const PriceVoteResult(PriceVoteStatus.ignored);

        final priceData = Map<String, dynamic>.from(priceSnap.data() ?? const <String, dynamic>{});
        final status = (priceData['status'] ?? 'active').toString();
        if (status != 'active') return const PriceVoteResult(PriceVoteStatus.ignored);

        final ownerUidFromDoc = (priceData['createdByUid'] ?? priceData['userId'] ?? '').toString();
        final ownerUid = ownerUidFromDoc.isNotEmpty ? ownerUidFromDoc : priceOwnerUid;
        final ownerRef = _usersRef.doc(ownerUid);
        if (ownerUid.trim().isEmpty) {
          return const PriceVoteResult(PriceVoteStatus.ignored);
        }
        if (ownerUid == voterUid) {
          return const PriceVoteResult(PriceVoteStatus.selfVoteBlocked);
        }

        final upCurrent = (priceData['verifyUpCount'] as num?)?.toInt() ??
            (priceData['upVotes'] as num?)?.toInt() ??
            (priceData['verifyYesCount'] as num?)?.toInt() ??
            (priceData['verification'] is Map ? ((priceData['verification'] as Map)['upCount'] as num?)?.toInt() : null) ??
            0;
        final downCurrent = (priceData['verifyDownCount'] as num?)?.toInt() ??
            (priceData['downVotes'] as num?)?.toInt() ??
            (priceData['verifyNoCount'] as num?)?.toInt() ??
            (priceData['verification'] is Map ? ((priceData['verification'] as Map)['downCount'] as num?)?.toInt() : null) ??
            0;

        final voteSnap = await txn.get(voteRef);
        if (voteSnap.exists) {
          return PriceVoteResult(
            PriceVoteStatus.alreadyVoted,
            upCount: upCurrent,
            downCount: downCurrent,
            score: upCurrent - downCurrent,
          );
        }

        var up = upCurrent;
        var down = downCurrent;
        if (vote == 1) {
          up += 1;
        } else {
          down += 1;
        }

        final voterSnap = await txn.get(voterRef);
        final voterData = voterSnap.data() ?? const <String, dynamic>{};
        final voterName = (voterData['name'] ?? voterData['displayName'] ?? '').toString();
        final voterLevel = (voterData['level'] ?? voterData['tierName'] ?? 'Standart').toString();
        final voterTrust = ((voterData['reliabilityScore'] as num?)?.toDouble() ?? 0).clamp(0, 100);
        final isAdminVoter = (voterData['isAdmin'] as bool?) == true || (voterData['role'] ?? '').toString() == 'admin';

        txn.set(voteRef, {
          'uid': voterUid,
          'vote': vote == 1 ? 'up' : 'down',
          'createdAt': FieldValue.serverTimestamp(),
          'userName': voterName,
          'userLevelSnapshot': voterLevel,
          'userTrustSnapshot': voterTrust,
        }, SetOptions(merge: true));

        if (up < 0) up = 0;
        if (down < 0) down = 0;

        final score = up - down;
        final total = up + down;
        final verificationStatus = total < 3
            ? 'unverified'
            : (score >= 3 && up >= 3)
                ? 'trusted'
                : (down >= 3 && score <= -2)
                    ? 'contested'
                    : 'unverified';

        txn.set(priceRef, {
          'verifyUpCount': up,
          'verifyDownCount': down,
          'verifyScore': score,
          'upVotes': up,
          'downVotes': down,
          'verifyYesCount': up,
          'verifyNoCount': down,
          'verifiedCount': up,
          'unverifiedCount': down,
          'score': score,
          'verificationScore': score,
          'verificationStatus': verificationStatus,
          'verification.upCount': up,
          'verification.downCount': down,
          'verification.score': score,
          'verification.updatedAt': FieldValue.serverTimestamp(),
          'lastVerifiedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        final ownerSnap = await txn.get(ownerRef);
        final ownerData = ownerSnap.data() ?? <String, dynamic>{};
        final currentReliability = ((ownerData['reliabilityScore'] as num?)?.toDouble() ?? 0).round();
        final baseDelta = vote == 1 ? 1 : -1;
        final appliedDelta = isAdminVoter ? baseDelta * 2 : baseDelta;
        final reliabilityScore = (currentReliability + appliedDelta).clamp(0, 100);

        txn.set(ownerRef, {
          'reliabilityScore': reliabilityScore,
          'trust.score': reliabilityScore,
          'trust.trustPercent': reliabilityScore,
          'trustScorePercent': reliabilityScore,
          'tierName': _trustTierFromScore(reliabilityScore),
          'levelName': _trustTierFromScore(reliabilityScore),
          'level': _trustTierFromScore(reliabilityScore),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        return PriceVoteResult(
          PriceVoteStatus.newVote,
          upCount: up,
          downCount: down,
          score: score,
        );
      });

      if (result.status == PriceVoteStatus.newVote) {
        try {
          final priceSnap = await _pricesRef.doc(priceId).get();
          final priceData = priceSnap.data() ?? const <String, dynamic>{};
          await _pointsService.awardEvent(
            uid: voterUid,
            eventType: 'verify_vote',
            meta: {
              'priceId': priceId,
              'productId': (priceData['productId'] ?? '').toString(),
              'storeId': (priceData['storeId'] ?? priceData['branchStoreId'] ?? '').toString(),
            },
            ensureUniqueByMeta: true,
          );
        } catch (e) {
          debugPrint('voteOnPrice points award failed: $e');
        }
      }

      return result;
    } on FirebaseException catch (e, st) {
      _logFirestoreQueryError('voteOnPrice', e, st);
      return const PriceVoteResult(PriceVoteStatus.ignored);
    } catch (e, st) {
      _logFirestoreQueryError('voteOnPrice', e, st);
      return const PriceVoteResult(PriceVoteStatus.ignored);
    }
  }

  Future<PriceVoteResult> verifyPrice(String priceId, String voterId, bool isVerified) async {
    final priceSnap = await _pricesRef.doc(priceId).get();
    final data = priceSnap.data() ?? const <String, dynamic>{};
    final ownerUid = ((data['createdByUid'] ?? data['userId']) ?? '').toString();
    if (ownerUid.isEmpty) {
      return const PriceVoteResult(PriceVoteStatus.ignored);
    }

    return voteOnPrice(
      priceId: priceId,
      priceOwnerUid: ownerUid,
      vote: isVerified ? 1 : -1,
      voterUid: voterId,
    );
  }

  Future<bool> hasUserVotedPrice(String priceId, String userId) async {
    return hasUserVerifiedPrice(priceId, userId);
  }

  Future<bool> hasUserVerifiedPrice(String priceId, String userId) async {
    final voteDoc = await _pricesRef.doc(priceId).collection('verifications').doc(userId).get();
    return voteDoc.exists;
  }

  Stream<String?> streamUserVoteValue(String priceId, String uid) {
    if (priceId.trim().isEmpty || uid.trim().isEmpty) return const Stream<String?>.empty();
    return _pricesRef.doc(priceId).collection('verifications').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data() ?? const <String, dynamic>{};
      final raw = (data['vote'] ?? data['value'] ?? '').toString();
      if (raw == 'up' || raw == 'yes') return 'yes';
      if (raw == 'down' || raw == 'no') return 'no';
      return null;
    });
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
      'priceEntryId': priceId,
      'contextId': contextId,
      'reason': reason,
      'reporterUserId': userId,
      'reporterUid': userId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedBy': null,
      'resolvedAt': null,
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
    final query = SafeQueryBuilder.safeWhere(_pricesRef, 'isPending', true, expectedType: bool);
    return query
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
    final query = SafeQueryBuilder.safeWhere(_commentsRef, 'productId', productId, expectedType: String);
    return query
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
    if (comment.text.trim().length >= 12) {
      await _pointsService.awardEvent(
        uid: comment.userId,
        eventType: 'comment',
        meta: {'commentId': doc.id, 'productId': comment.productId},
      );
    }
    return doc.id;
  }

  Future<void> likeComment(String commentId, String userId) async {
    final doc = await _commentsRef.doc(commentId).get();
    if (doc.exists) {
      final raw = doc.data();
      final data = raw is Map<String, dynamic>
          ? Map<String, dynamic>.from(raw)
          : null;
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
    final primary = SafeQueryBuilder.safeWhere(
      _notificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).snapshots();
    final legacy = SafeQueryBuilder.safeWhere(
      _legacyNotificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).snapshots();

    return primary.asyncMap((primarySnapshot) async {
      final legacySnapshot = await legacy.first;
      final merged = <NotificationModel>[
        ...primarySnapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)),
        ...legacySnapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)),
      ];

      final byId = <String, NotificationModel>{};
      for (final notification in merged) {
        byId[notification.id] = notification;
      }
      final list = byId.values.toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<int> getUnreadNotificationCount(String userId) {
    return getNotifications(userId).map(
      (list) => list.where((item) => !item.isRead).length,
    );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    final doc = await _notificationsRef.doc(notificationId).get();
    if (doc.exists) {
      await _notificationsRef.doc(notificationId).update({'isRead': true});
      return;
    }

    final legacyDoc = await _legacyNotificationsRef.doc(notificationId).get();
    if (legacyDoc.exists) {
      await _legacyNotificationsRef.doc(notificationId).update({'isRead': true});
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final primarySnapshot = await SafeQueryBuilder.safeWhere(
      _notificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).get();
    final legacySnapshot = await SafeQueryBuilder.safeWhere(
      _legacyNotificationsRef,
      'userId',
      userId,
      expectedType: String,
    ).get();

    for (final doc in [...primarySnapshot.docs, ...legacySnapshot.docs]) {
      final raw = doc.data();
      final map = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
      final isRead = map['isRead'] == true;
      if (!isRead) {
        batch.update(doc.reference, {'isRead': true});
      }
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
    final query = SafeQueryBuilder.safeWhere(_bannersRef, 'isActive', true, expectedType: bool);
    return query
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




  Future<void> _incrementVoterTrustForVote(String uid) async {
    if (uid.trim().isEmpty) return;
    final dayKey = DateTime.now().toUtc().toIso8601String().split('T').first.replaceAll('-', '');
    final dailyRef = _usersRef.doc(uid).collection('trust_daily').doc(dayKey);
    final userRef = _usersRef.doc(uid);

    await _firestore.runTransaction((txn) async {
      final dailySnap = await txn.get(dailyRef);
      final current = (dailySnap.data()?['voteContribution'] as num?)?.toInt() ?? 0;
      if (current >= 10) {
        txn.set(dailyRef, {'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
        return;
      }

      txn.set(dailyRef, {
        'voteContribution': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.set(userRef, {
        'reliabilityScore': FieldValue.increment(0.1),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _applyPriceAuthorTrustThreshold({
    required String priceId,
    required String ownerUid,
  }) async {
    if (priceId.trim().isEmpty || ownerUid.trim().isEmpty) return;

    final priceRef = _pricesRef.doc(priceId);
    final trustEventRef = _usersRef.doc(ownerUid).collection('trust_events').doc(priceId);
    final ownerRef = _usersRef.doc(ownerUid);

    await _firestore.runTransaction((txn) async {
      final priceSnap = await txn.get(priceRef);
      if (!priceSnap.exists) return;
      final priceData = priceSnap.data() ?? const <String, dynamic>{};
      final yes = (priceData['verifyYesCount'] as num?)?.toInt() ?? (priceData['upVotes'] as num?)?.toInt() ?? 0;
      final no = (priceData['verifyNoCount'] as num?)?.toInt() ?? (priceData['downVotes'] as num?)?.toInt() ?? 0;
      final net = yes - no;

      final targetTier = net >= 3
          ? 3
          : net <= -3
              ? -3
              : 0;
      if (targetTier == 0) return;

      final trustEventSnap = await txn.get(trustEventRef);
      final appliedTier = (trustEventSnap.data()?['appliedTier'] as num?)?.toInt() ?? 0;
      if (appliedTier == targetTier) return;

      final scoreDelta = targetTier > appliedTier ? 1 : -1;
      txn.set(ownerRef, {
        'reliabilityScore': FieldValue.increment(scoreDelta),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      txn.set(trustEventRef, {
        'appliedTier': targetTier,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  String _trustTierFromScore(int score) {
    if (score >= 80) return 'Elmas';
    if (score >= 60) return 'Altın';
    if (score >= 40) return 'Gümüş';
    if (score >= 20) return 'Bronz';
    return 'Standart';
  }

  Stream<Map<String, dynamic>> streamUserTrustProfile(String uid) {
    if (uid.trim().isEmpty) {
      return Stream.value(const {
        'displayName': 'Kullanıcı',
        'trustScorePercent': 0,
        'tierName': 'Standart',
      });
    }

    return _usersRef.doc(uid).snapshots().map((doc) {
      final data = doc.data() ?? <String, dynamic>{};
      final score = ((data['reliabilityScore'] as num?)?.toDouble() ?? 0).clamp(0, 100).round();
      final level = (data['level'] ?? data['tierName'] ?? '').toString().trim();
      return {
        'displayName': (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString(),
        'trustScorePercent': score,
        'tierName': level.isNotEmpty ? level : _trustTierFromScore(score),
      };
    });
  }

  Future<Map<String, dynamic>> getUserTrustProfile(String uid) async {
    if (uid.trim().isEmpty) {
      return {
        'displayName': 'Kullanıcı',
        'trustScorePercent': 0,
        'tierName': 'Standart',
      };
    }

    final doc = await _usersRef.doc(uid).get();
    final data = doc.data() ?? <String, dynamic>{};
    final score = ((data['reliabilityScore'] as num?)?.toDouble() ?? 0).clamp(0, 100).round();
    final level = (data['level'] ?? data['tierName'] ?? '').toString().trim();

    return {
      'displayName': (data['name'] ?? data['displayName'] ?? 'Kullanıcı').toString(),
      'trustScorePercent': score,
      'tierName': level.isNotEmpty ? level : _trustTierFromScore(score),
    };
  }

  Future<void> _refreshUserTrust(String uid) async {
    if (uid.trim().isEmpty) return;
    final userRef = _usersRef.doc(uid);
    final snap = await userRef.get();
    final data = snap.data() ?? <String, dynamic>{};
    final trust = Map<String, dynamic>.from(data['trust'] as Map? ?? const {});
    final up = (trust['upTotal'] as num?)?.toInt() ?? 0;
    final down = (trust['downTotal'] as num?)?.toInt() ?? 0;
    final total = up + down;
    final percent = total <= 0 ? 0 : ((up / total) * 100).round().clamp(0, 100);
    final score = up - down;

    final level = _trustTierFromScore(percent);

    await userRef.set({
      'trust': {
        'upTotal': up,
        'downTotal': down,
        'score': score,
        'trustPercent': percent,
      },
      'trustScorePercent': percent,
      'reliabilityScore': percent,
      'tierName': level,
      'levelName': level,
      'level': level,
    }, SetOptions(merge: true));
  }

  Future<void> softDeletePrice({required String priceId, required String deletedByUid}) async {
    await _pricesRef.doc(priceId).set({
      'status': 'deleted',
      'deletedAt': FieldValue.serverTimestamp(),
      'deletedByUid': deletedByUid,
    }, SetOptions(merge: true));
  }

  Future<PriceStatusMigrationResult> migrateMissingPriceStatus({
    int batchSize = 300,
    void Function(int updated, int scanned)? onProgress,
  }) async {
    final safeBatchSize = batchSize.clamp(200, 500).toInt();
    QueryDocumentSnapshot<Map<String, dynamic>>? lastDocument;
    var updatedCount = 0;
    var scannedCount = 0;

    while (true) {
      Query<Map<String, dynamic>> query = _pricesRef.limit(safeBatchSize);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      var updatedInBatch = 0;

      for (final doc in snapshot.docs) {
        scannedCount++;
        final data = doc.data();
        if (!data.containsKey('status')) {
          batch.update(doc.reference, {'status': 'active'});
          updatedInBatch++;
        }
      }

      if (updatedInBatch > 0) {
        await batch.commit();
      }

      updatedCount += updatedInBatch;
      onProgress?.call(updatedCount, scannedCount);

      lastDocument = snapshot.docs.last;
      if (snapshot.docs.length < safeBatchSize) break;
    }

    return PriceStatusMigrationResult(
      updatedCount: updatedCount,
      scannedCount: scannedCount,
    );
  }

  Future<void> updateUserByAdmin(String userId, Map<String, dynamic> data) async {
    await _usersRef.doc(userId).set(data, SetOptions(merge: true));

    final hasPointsUpdate = data.containsKey('totalPoints') ||
        data.containsKey('pointsTotal') ||
        data.containsKey('points');
    final hasRoleUpdate = data.containsKey('role') || data.containsKey('isAdmin');
    if (hasPointsUpdate || hasRoleUpdate) {
      await _pointsService.recomputeUserGamification(userId);
    }
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

    final uniqueIds = productIds.toSet().toList();
    return _productsRef.snapshots().map((snapshot) {
      final productMap = <String, ProductModel>{};
      for (final doc in snapshot.docs) {
        final product = ProductModel.fromFirestore(doc);
        if (uniqueIds.contains(product.id)) {
          productMap[product.id] = product;
        }
      }
      return uniqueIds
          .where(productMap.containsKey)
          .map((id) => productMap[id]!)
          .toList();
    });
  }


  // =========================================================================
  // CATEGORIES
  // =========================================================================

  CollectionReference get _categoriesRef => _firestore.collection('categories');

  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(CategoryModel.fromFirestore)
          .where((category) => category.isActive)
          .toList();
      list.sort((a, b) {
        final aOrder = a.order;
        final bOrder = b.order;
        if (aOrder != null && bOrder != null) {
          return aOrder.compareTo(bOrder);
        }
        if (aOrder != null) return -1;
        if (bOrder != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return list;
    });
  }

  Future<String> addCategory(
    String name,
    String iconName, {
    String? imageUrl,
    String? imagePath,
    bool isActive = true,
    int? order,
  }) async {
    final doc = await _categoriesRef.add({
      'name': name,
      'iconName': iconName,
      'isActive': isActive,
      if (order != null) 'order': order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (imagePath != null) 'imagePath': imagePath,
    });
    return doc.id;
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    await _categoriesRef.doc(categoryId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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

  // =========================================================================
  // REPORTS
  // =========================================================================

  CollectionReference get _reportsRef => _firestore.collection('reports');

  Stream<List<Map<String, dynamic>>> getReports() {
    return _reportsRef.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final raw = doc.data();
        final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
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
    if (status == 'confirmed') {
      await _pointsService.handleReportConfirmed(reportId);
    }
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
      try {
        var query = SafeQueryBuilder.safeWhereIn(_pricesRef, 'productId', chunk);
        query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
        final snapshot = await query.get();
        results.addAll(snapshot.docs.map((doc) => PriceModel.fromFirestore(doc)));
      } catch (e) {
        debugPrint("FIRESTORE QUERY ERROR -> $e");
      }
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
      try {
        var query = SafeQueryBuilder.safeWhereIn(_pricesRef, 'productId', chunk);
        query = SafeQueryBuilder.safeWhere(query, 'status', 'active', expectedType: String);
        final snapshot = await query.get();
        results.addAll(snapshot.docs.map((doc) => PriceModel.fromFirestore(doc)));
      } catch (e) {
        debugPrint("FIRESTORE QUERY ERROR -> $e");
      }
    }
    return results;
  }

  Stream<List<ActualModel>> getActualsForAdmin({bool? isActive}) {
    Query<Map<String, dynamic>> query = _actualsRef;
    if (isActive != null) {
      query = query.where('isActive', isEqualTo: isActive);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map(ActualModel.fromFirestore).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Stream<ActualModel?> getLatestActiveActualForUser() {
    return _actualsRef.where('isActive', isEqualTo: true).snapshots().map((snapshot) {
      final now = DateTime.now();
      final active = snapshot.docs
          .map(ActualModel.fromFirestore)
          .where((actual) => !actual.startDate.isAfter(now) && !actual.endDate.isBefore(now))
          .toList();
      if (active.isEmpty) return null;
      active.sort((a, b) {
        final createdAtCompare = b.createdAt.compareTo(a.createdAt);
        if (createdAtCompare != 0) return createdAtCompare;
        return b.startDate.compareTo(a.startDate);
      });
      return active.first;
    });
  }

  Stream<List<ActualItemModel>> getActualItems(String actualId) {
    return _actualsRef
        .doc(actualId)
        .collection('items')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(ActualItemModel.fromFirestore).toList());
  }

  Future<String> addActual(ActualModel actual) async {
    final payload = actual.toFirestore();
    payload['createdAt'] = FieldValue.serverTimestamp();
    payload['updatedAt'] = FieldValue.serverTimestamp();
    final doc = await _actualsRef.add(payload);
    return doc.id;
  }

  Future<void> updateActual(String actualId, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data);
    payload['updatedAt'] = FieldValue.serverTimestamp();
    await _actualsRef.doc(actualId).update(payload);
  }

  Future<void> setActualActive(String actualId, bool isActive) async {
    await _actualsRef.doc(actualId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> addActualItem(String actualId, ActualItemModel item) async {
    final payload = item.toFirestore();
    payload['createdAt'] = FieldValue.serverTimestamp();
    final doc = await _actualsRef.doc(actualId).collection('items').add(payload);
    return doc.id;
  }

  Future<void> updateActualItem(String actualId, String itemId, Map<String, dynamic> data) async {
    await _actualsRef.doc(actualId).collection('items').doc(itemId).update(data);
  }

  Future<void> deleteActualItem(String actualId, String itemId) async {
    await _actualsRef.doc(actualId).collection('items').doc(itemId).delete();
  }

  Stream<List<Map<String, dynamic>>> getWeeklyDeals() {
    return _weeklyDealsRef.orderBy('startDate', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getDealItems(String dealId) {
    return _weeklyDealsRef.doc(dealId).collection('deal_items').snapshots().map((snapshot) {
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }

  Stream<Map<String, int>> getStockSummary({required String dealItemId, required String branchId}) {
    return _stockReportsRef
        .where('dealItemId', isEqualTo: dealItemId)
        .where('branchId', isEqualTo: branchId)
        .snapshots()
        .map((snapshot) {
      var inStock = 0;
      var low = 0;
      var out = 0;
      for (final doc in snapshot.docs) {
        final status = (doc.data()['status'] ?? '').toString();
        if (status == 'in_stock') inStock++;
        if (status == 'low_stock') low++;
        if (status == 'out_of_stock') out++;
      }
      return {
        'in_stock': inStock,
        'low_stock': low,
        'out_of_stock': out,
      };
    });
  }

  Future<bool> submitStockReport({
    required String uid,
    required String dealItemId,
    required String branchId,
    required String status,
  }) async {
    final reportId = '${uid}_${dealItemId}_$branchId';
    final rewardId = '${uid}_${dealItemId}_$branchId';
    final now = DateTime.now();
    var rewarded = false;
    await _firestore.runTransaction((txn) async {
      final reportRef = _stockReportsRef.doc(reportId);
      final rewardRef = _firestore.collection('stock_report_rewards').doc(rewardId);
      final userRef = _usersRef.doc(uid);
      final rewardSnap = await txn.get(rewardRef);
      final lastRewardAt = (rewardSnap.data()?['lastRewardAt'] as Timestamp?)?.toDate();
      final canReward = lastRewardAt == null || now.difference(lastRewardAt).inHours >= 6;

      txn.set(reportRef, {
        'dealItemId': dealItemId,
        'branchId': branchId,
        'status': status,
        'createdByUid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (canReward) {
        rewarded = true;
        txn.set(rewardRef, {'lastRewardAt': Timestamp.fromDate(now)}, SetOptions(merge: true));
        txn.set(userRef.collection('points_log').doc(), {
          'type': 'stock_report',
          'points': 2,
          'dealItemId': dealItemId,
          'branchId': branchId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        txn.update(userRef, {'points': FieldValue.increment(2)});
        txn.set(userRef.collection('stats').doc('summary'), {
          'stockReportsCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });

    await _grantStockHunterBadges(uid);
    return rewarded;
  }

  Future<void> _grantStockHunterBadges(String uid) async {
    final userRef = _usersRef.doc(uid);
    final statsDoc = await userRef.collection('stats').doc('summary').get();
    final count = (statsDoc.data()?['stockReportsCount'] as num?)?.toInt() ?? 0;
    final tiers = <int, String>{20: 'stock_hunter_1', 50: 'stock_hunter_2', 100: 'stock_hunter_3'};
    for (final threshold in tiers.keys.toList()..sort()) {
      if (count < threshold) continue;
      final badgeId = tiers[threshold]!;
      final badgeRef = userRef.collection('badges').doc(badgeId);
      final badgeDoc = await badgeRef.get();
      if (badgeDoc.exists) continue;
      await badgeRef.set({
        'badgeId': badgeId,
        'unlockedAt': FieldValue.serverTimestamp(),
      });
      await userRef.collection('badgeEvents').add({
        'badgeId': badgeId,
        'badgeName': 'Stok Avcısı',
        'description': 'Stok bildirimi katkın için teşekkürler.',
        'seen': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<bool> validateStockReport({
    required String reportId,
    required String validatorUid,
    required String result,
  }) async {
    final validationId = '${reportId}_$validatorUid';
    final validationRef = _stockValidationRef.doc(validationId);
    final reportRef = _stockReportsRef.doc(reportId);
    bool rewarded = false;

    await _firestore.runTransaction((txn) async {
      final existing = await txn.get(validationRef);
      if (existing.exists) return;
      txn.set(validationRef, {
        'reportId': reportId,
        'validatorUid': validatorUid,
        'result': result,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });

    final reportValidations = await _stockValidationRef.where('reportId', isEqualTo: reportId).get();
    final correctCount = reportValidations.docs.where((doc) => (doc.data()['result'] ?? '').toString() == 'correct').length;
    if (correctCount >= 3) {
      await _firestore.runTransaction((txn) async {
        final reportDoc = await txn.get(reportRef);
        final reportData = reportDoc.data() ?? <String, dynamic>{};
        if (reportData['bonusAwarded'] == true) return;
        final ownerUid = (reportData['createdByUid'] ?? '').toString();
        if (ownerUid.isEmpty) return;
        final userRef = _usersRef.doc(ownerUid);
        txn.update(reportRef, {'bonusAwarded': true});
        txn.update(userRef, {'points': FieldValue.increment(3)});
        txn.set(userRef.collection('points_log').doc(), {
          'type': 'stock_validation_bonus',
          'points': 3,
          'reportId': reportId,
          'createdAt': FieldValue.serverTimestamp(),
        });
        rewarded = true;
      });
    }
    return rewarded;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pointsLogStream(String uid) {
    return _usersRef.doc(uid).collection('points_log').orderBy('createdAt', descending: true).limit(40).snapshots();
  }

  Future<void> toggleFavorite({required String uid, required String productId, Map<String, dynamic>? payload}) async {
    final ref = _usersRef.doc(uid).collection('favorites').doc(productId);
    final doc = await ref.get();
    if (doc.exists) {
      await ref.delete();
      return;
    }
    await ref.set({
      'productId': productId,
      'createdAt': FieldValue.serverTimestamp(),
      ...?payload,
    });
  }

  Stream<bool> isFavoriteStream({required String uid, required String productId}) {
    return _usersRef.doc(uid).collection('favorites').doc(productId).snapshots().map((doc) => doc.exists);
  }

  Future<void> addRecentlyViewed({required String uid, required ProductModel product}) async {
    final ref = _usersRef.doc(uid).collection('recently_viewed').doc(product.id);
    await ref.set({
      'productId': product.id,
      'productName': product.name,
      'imageUrl': product.effectiveImage,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final list = await _usersRef.doc(uid).collection('recently_viewed').orderBy('updatedAt', descending: true).get();
    if (list.docs.length > 10) {
      for (final doc in list.docs.skip(10)) {
        await doc.reference.delete();
      }
    }
  }

  Stream<List<Map<String, dynamic>>> recentlyViewedStream(String uid) {
    return _usersRef.doc(uid).collection('recently_viewed').orderBy('updatedAt', descending: true).limit(10).snapshots().map((snapshot) {
      return snapshot.docs.map((d) => {'id': d.id, ...d.data()}).toList();
    });
  }




}
