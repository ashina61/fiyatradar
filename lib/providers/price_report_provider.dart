import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/category_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store.dart';
import '../models/store_model.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'product_provider.dart';

class AddPriceState {
  const AddPriceState({
    this.price = '',
    this.productName = '',
    this.barcode,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.selectedProductId,
    this.selectedProductImageUrl,
    this.lockedCategoryByProduct = false,
    this.productSuggestions = const [],
    this.activeTab = 0,
    this.searchQuery = '',
    this.selectedStore,
    this.selectedStoreId,
    this.selectedStoreName,
    this.categories = const [],
    this.nearbyStores = const [],
    this.onlineStores = const [],
    this.isStoresLoading = false,
    this.storesError,
    this.locationMessage,
    this.isLoading = false,
    this.error,
  });

  final String price;
  final String productName;
  final String? barcode;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final String? selectedProductId;
  final String? selectedProductImageUrl;
  final bool lockedCategoryByProduct;
  final List<ProductModel> productSuggestions;
  final int activeTab;
  final String searchQuery;
  final Store? selectedStore;
  final String? selectedStoreId;
  final String? selectedStoreName;
  final List<CategoryModel> categories;
  final List<Store> nearbyStores;
  final List<Store> onlineStores;
  final bool isStoresLoading;
  final String? storesError;
  final String? locationMessage;
  final bool isLoading;
  final String? error;

  AddPriceState copyWith({
    String? price,
    String? productName,
    String? barcode,
    bool clearBarcode = false,
    String? selectedCategoryId,
    String? selectedCategoryName,
    bool clearCategory = false,
    String? selectedProductId,
    String? selectedProductImageUrl,
    bool clearSelectedProduct = false,
    bool? lockedCategoryByProduct,
    List<ProductModel>? productSuggestions,
    int? activeTab,
    String? searchQuery,
    Store? selectedStore,
    bool clearSelectedStore = false,
    String? selectedStoreId,
    String? selectedStoreName,
    List<CategoryModel>? categories,
    List<Store>? nearbyStores,
    List<Store>? onlineStores,
    bool? isStoresLoading,
    String? storesError,
    bool clearStoresError = false,
    String? locationMessage,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return AddPriceState(
      price: price ?? this.price,
      productName: productName ?? this.productName,
      barcode: clearBarcode ? null : (barcode ?? this.barcode),
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      selectedCategoryName: clearCategory
          ? null
          : (selectedCategoryName ?? this.selectedCategoryName),
      selectedProductId:
          clearSelectedProduct ? null : (selectedProductId ?? this.selectedProductId),
      selectedProductImageUrl: clearSelectedProduct
          ? null
          : (selectedProductImageUrl ?? this.selectedProductImageUrl),
      lockedCategoryByProduct:
          lockedCategoryByProduct ?? this.lockedCategoryByProduct,
      productSuggestions: productSuggestions ?? this.productSuggestions,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStore: clearSelectedStore ? null : (selectedStore ?? this.selectedStore),
      selectedStoreId:
          clearSelectedStore ? null : (selectedStoreId ?? this.selectedStoreId),
      selectedStoreName: clearSelectedStore
          ? null
          : (selectedStoreName ?? this.selectedStoreName),
      categories: categories ?? this.categories,
      nearbyStores: nearbyStores ?? this.nearbyStores,
      onlineStores: onlineStores ?? this.onlineStores,
      isStoresLoading: isStoresLoading ?? this.isStoresLoading,
      storesError: clearStoresError ? null : (storesError ?? this.storesError),
      locationMessage: locationMessage ?? this.locationMessage,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isNearbyMode => activeTab == 0;

  List<Store> get visibleStores {
    final source = isNearbyMode ? nearbyStores : onlineStores;
    final filtered = searchQuery.trim().isEmpty
        ? source
        : source
            .where((s) => s.name.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList(growable: false);
    final ordered = List<Store>.of(filtered);
    if (isNearbyMode) {
      ordered.sort((a, b) {
        final ad = a.distanceMeters;
        final bd = b.distanceMeters;
        if (ad != null && bd != null) return ad.compareTo(bd);
        if (ad != null) return -1;
        if (bd != null) return 1;
        return 0;
      });
    }
    return ordered.take(5).toList(growable: false);
  }
}

final addPriceProvider = StateNotifierProvider<AddPriceNotifier, AddPriceState>((ref) {
  return AddPriceNotifier(
    ref.read(firestoreServiceProvider),
    LocationService(),
  );
});

class AddPriceNotifier extends StateNotifier<AddPriceState> {
  AddPriceNotifier(this._firestore, this._locationService)
      : super(const AddPriceState()) {
    loadStoresAndCategories();
  }

  final FirestoreService _firestore;
  final LocationService _locationService;
  Timer? _productSearchDebounce;
  LocationData? _cachedLocationData;


  void _log(String message) {
    if (!kDebugMode) return;
    debugPrint(message);
  }

  void _logStack(Object error, StackTrace stackTrace, {required String label}) {
    if (!kDebugMode) return;
    _log('$label: $error');
    debugPrintStack(stackTrace: stackTrace, label: '$label STACK');
  }

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadStoresAndCategories() async {
    state = state.copyWith(
      isStoresLoading: true,
      clearStoresError: true,
      locationMessage: null,
    );
    try {
      _log('[AddPrice.loadStoresAndCategories] Firestore query => collection=categories, where=[], orderBy=[]');
      _log('[AddPrice.loadStoresAndCategories] Firestore query => collection=stores, where=[], orderBy=[]');

      final categories = await _firestore.getCategories().first;
      final stores = await _firestore.getAllStoresStream().first;
      _cachedLocationData ??= await _locationService.getLocationData();
      final userPosition = _cachedLocationData?.position;
      final userLat = userPosition?.latitude;
      final userLng = userPosition?.longitude;
      _log('USER_LOCATION: ${userLat != null && userLng != null ? '$userLat,$userLng' : 'null'}');
      final locationMessage = userPosition == null
          ? 'Konum izni olmadan mesafe hesaplanamiyor.'
          : null;

      final nearby = stores
          .where((s) => s.status == StoreStatus.active && !s.isOnline)
          .map((store) => _mapStore(store, userPosition))
          .toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      final online = stores
          .where((s) => s.status == StoreStatus.active && s.isOnline)
          .map((store) => _mapStore(store, userPosition))
          .toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));

      if (categories.isNotEmpty) {
        final sample = categories.first;
        _log('[AddPrice] Category mapped fields: id=${sample.id}, title=${sample.title}, isActive=${sample.isActive}');
      }
      if (stores.isNotEmpty) {
        final sample = stores.first;
        _log('[AddPrice] Store mapped fields: id=${sample.id}, displayName=${sample.displayName}, type=${sample.type.name}, status=${sample.status.name}, lat=${sample.lat}, lng=${sample.lng}');
      }

      state = state.copyWith(
        categories: categories,
        nearbyStores: nearby,
        onlineStores: online,
        isStoresLoading: false,
        locationMessage: locationMessage,
        clearStoresError: true,
      );
    } catch (e, st) {
      _logStack(e, st, label: '[AddPrice.loadStoresAndCategories] ERROR');
      state = state.copyWith(
        isStoresLoading: false,
        storesError: e.toString(),
        nearbyStores: const [],
        onlineStores: const [],
      );
    }
  }

  Store _mapStore(StoreModel model, Position? userPosition) {
    final hasCoordinates = model.lat != 0 && model.lng != 0;
    final lat = hasCoordinates ? model.lat : null;
    final lng = hasCoordinates ? model.lng : null;
    _log('STORE_LOC: ${model.id} ${lat != null && lng != null ? '$lat,$lng' : 'null'}');
    final distanceMeters = lat != null && lng != null && userPosition != null
        ? _haversineMeters(
            userPosition.latitude,
            userPosition.longitude,
            lat,
            lng,
          ).round()
        : null;
    _log('DISTANCE: ${model.id} ${distanceMeters ?? 'null'}');

    return Store(
      id: model.id,
      name: model.displayName,
      type: model.isOnline ? 'online' : 'nearby',
      distanceMeters: distanceMeters,
      logoUrl: model.displayName.isNotEmpty ? model.displayName[0].toUpperCase() : '?',
      subtitle: [model.district, model.city].where((e) => e.trim().isNotEmpty).join(', ').trim().isEmpty
          ? null
          : [model.district, model.city].where((e) => e.trim().isNotEmpty).join(', '),
    );
  }

  double _haversineMeters(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    const earthRadius = 6371000.0;
    final dLat = _degToRad(endLatitude - startLatitude);
    final dLng = _degToRad(endLongitude - startLongitude);
    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        math.cos(_degToRad(startLatitude)) *
            math.cos(_degToRad(endLatitude)) *
            (math.sin(dLng / 2) * math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);

  void setPrice(String value) => state = state.copyWith(price: value);
  void onProductInputChanged(String value) {
    _productSearchDebounce?.cancel();

    final normalizedInput = value.trim();
    final wasSelected = state.selectedProductId != null;
    final shouldClearSelection =
        wasSelected && normalizedInput.toLowerCase() != state.productName.trim().toLowerCase();

    if (shouldClearSelection) {
      _log('CATEGORY_LOCKED: false');
    }
    state = state.copyWith(
      productName: value,
      productSuggestions: const [],
      clearBarcode: true,
      clearSelectedProduct: shouldClearSelection,
      selectedProductImageUrl: shouldClearSelection ? null : state.selectedProductImageUrl,
      lockedCategoryByProduct: shouldClearSelection ? false : state.lockedCategoryByProduct,
    );

    if (normalizedInput.isEmpty) {
      _log('CATEGORY_LOCKED: false');
      state = state.copyWith(
        clearSelectedProduct: true,
        lockedCategoryByProduct: false,
        clearCategory: true,
        productSuggestions: const [],
      );
      return;
    }

    if (normalizedInput.length < 2) return;

    _productSearchDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _firestore.searchProductsByPrefix(normalizedInput, limit: 10);
        _log('PRODUCT_QUERY: $normalizedInput -> ${results.length} results');
        if (state.productName.trim().toLowerCase() != normalizedInput.toLowerCase()) return;
        state = state.copyWith(productSuggestions: results.take(5).toList(growable: false));
      } catch (_) {
        _log('PRODUCT_QUERY: $normalizedInput -> 0 results');
        state = state.copyWith(productSuggestions: const []);
      }
    });
  }

  void clearProductSuggestions() {
    if (state.productSuggestions.isEmpty) return;
    state = state.copyWith(productSuggestions: const []);
  }

  void selectProductSuggestion(ProductModel product, {String? barcode}) {
    final resolvedCategory = _resolveCategoryForProduct(product);
    _log('PRODUCT_SELECTED: ${product.id} ${product.name} category=${resolvedCategory?.id ?? 'null'}');
    _log('CATEGORY_LOCKED: ${resolvedCategory != null}');
    state = state.copyWith(
      productName: product.name,
      barcode: barcode ?? product.barcode,
      selectedProductId: product.id,
      selectedProductImageUrl: product.effectiveImage,
      productSuggestions: const [],
      selectedCategoryId: resolvedCategory?.id,
      selectedCategoryName: resolvedCategory?.title,
      clearCategory: resolvedCategory == null,
      lockedCategoryByProduct: resolvedCategory != null,
    );
  }

  CategoryModel? _resolveCategoryForProduct(ProductModel product) {
    final categoryValue = product.categories
        .map((item) => item.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    if (categoryValue.isEmpty) return null;

    final normalized = categoryValue.toLowerCase();
    for (final category in state.categories) {
      if (category.id.toLowerCase() == normalized ||
          category.title.toLowerCase() == normalized) {
        return category;
      }
    }
    return null;
  }

  void setCategory(CategoryModel? value) {
    if (state.lockedCategoryByProduct) return;
    state = state.copyWith(
      selectedCategoryId: value?.id,
      selectedCategoryName: value?.title,
    );
  }
  void setSearchQuery(String value) => state = state.copyWith(searchQuery: value);
  void setActiveTab(int value) => state = state.copyWith(activeTab: value, clearSelectedStore: true);
  void setSelectedStore(Store store) => state = state.copyWith(
        selectedStore: store,
        selectedStoreId: store.id,
        selectedStoreName: store.name,
      );
  void setBarcode(String? value) {
    final barcode = value?.trim();
    state = state.copyWith(
      barcode: barcode,
      productName: barcode ?? '',
      clearSelectedProduct: true,
      lockedCategoryByProduct: false,
      productSuggestions: const [],
    );
  }



  Future<void> initializeForProduct(String productId) async {
    final normalizedId = productId.trim();
    if (normalizedId.isEmpty) return;
    final product = await _firestore.getProduct(normalizedId);
    if (product == null) return;
    selectProductSuggestion(product, barcode: product.barcode);
  }
  Future<bool> applyScannedBarcode(String barcode) async {
    final normalizedBarcode = barcode.trim();
    if (normalizedBarcode.isEmpty) return false;

    final matches = await _firestore.searchProducts(normalizedBarcode);
    for (final product in matches) {
      if ((product.barcode?.trim() ?? '') == normalizedBarcode) {
        selectProductSuggestion(product, barcode: normalizedBarcode);
        return true;
      }
    }

    state = state.copyWith(
      productName: normalizedBarcode,
      barcode: normalizedBarcode,
      clearSelectedProduct: true,
      lockedCategoryByProduct: false,
      productSuggestions: const [],
      error: 'Bu barkoda ait katalog ürünü bulunamadı.',
    );
    return false;
  }

  Future<ProductModel?> _resolveProductByNameOrBarcode() async {
    final selectedProductId = state.selectedProductId?.trim() ?? '';
    if (selectedProductId.isEmpty) return null;
    _log('[AddPrice] Firestore query: products (id="$selectedProductId")');
    return _firestore.getProduct(selectedProductId);
  }

  Future<void> submitPrice({required String userId}) async {
    if (userId.trim().isEmpty) {
      throw Exception('Kullanıcı kimliği bulunamadı. Lütfen tekrar giriş yapın.');
    }

    final parsedPrice = double.tryParse(state.price.replaceAll(',', '.'));
    if (parsedPrice == null || parsedPrice <= 0) {
      throw Exception('Lütfen geçerli bir fiyat girin.');
    }
    if (state.selectedProductId == null || state.selectedProductId!.trim().isEmpty) {
      throw Exception('Lütfen katalogdan geçerli bir ürün seçin.');
    }
    if (state.productName.trim().isEmpty) {
      throw Exception('Lütfen ürün adını girin.');
    }
    if (state.selectedCategoryId == null) {
      throw Exception('Lütfen kategori seçin.');
    }
    if (state.selectedStoreId == null || state.selectedStoreName == null) {
      throw Exception('Lütfen bir mağaza seçin.');
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      ProductModel? product;
      final selectedProductId = state.selectedProductId?.trim() ?? '';
      if (selectedProductId.isNotEmpty) {
        _log('[AddPrice.submitPrice] resolve product by selectedProductId=$selectedProductId');
        product = await _firestore.getProduct(selectedProductId);
      }
      product ??= await _resolveProductByNameOrBarcode();

      if (product == null) {
        throw Exception('Bu ürün katalogda bulunamadı. Lütfen barkod okutun veya ürün adını kontrol edin.');
      }

      final userModel = await _firestore.getUserById(userId);
      final reporterName = (userModel?.username ?? userModel?.displayName ?? '').trim();
      final fallbackReporterName = reporterName.isEmpty ? 'Kullanıcı' : reporterName;
      final reporterIsAnonymous = FirebaseAuth.instance.currentUser?.isAnonymous ?? false;

      final payload = PriceModel(
        id: '',
        productId: product.id,
        productName: product.name.trim().isNotEmpty ? product.name : state.productName.trim(),
        selectedProductId: product.id,
        selectedCategoryId: state.selectedCategoryId,
        selectedStoreId: state.selectedStoreId,
        barcode: state.barcode,
        userId: userId,
        createdByUid: userId,
        userName: fallbackReporterName,
        price: parsedPrice,
        branchStoreId: state.selectedStoreId!,
        chainId: null,
        storeName: state.selectedStoreName,
        reportedAt: DateTime.now(),
        isPending: true,
        verificationStatus: 'unverified',
        status: 'active',
        reporterUid: userId,
        reporterName: fallbackReporterName,
        reporterIsAnonymous: reporterIsAnonymous,
      );

      _log('[AddPrice] Firestore write target: priceReports (+ product mirror)');
      _log('[AddPrice.submitPrice] payload => ${payload.toFirestore()}');

      await _firestore.addPriceReport(payload);

      final latestPrice = await _firestore.getLatestPrice(product.id);
      _log(
        '[AddPrice.submitPrice] latest verification => productId=${product.id}, latestPriceId=${latestPrice?.id}, latestProductId=${latestPrice?.productId}',
      );

      state = state.copyWith(
        isLoading: false,
        price: '',
        productName: '',
        searchQuery: '',
        clearCategory: true,
        clearSelectedStore: true,
        clearBarcode: true,
        clearSelectedProduct: true,
        lockedCategoryByProduct: false,
        productSuggestions: const [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitProductSuggestion({required String userId}) async {
    final name = state.productName.trim();
    if (userId.trim().isEmpty) {
      throw Exception('Kullanıcı kimliği bulunamadı.');
    }
    if (name.length < 2) {
      throw Exception('Ürün adı en az 2 karakter olmalı.');
    }

    await _firestore.addProductSuggestion(
      name: name,
      barcode: state.barcode,
      category: state.selectedCategoryName,
      userId: userId,
    );
  }
}
