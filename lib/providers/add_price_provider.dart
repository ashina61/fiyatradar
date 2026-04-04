import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store.dart';
import '../models/store_model.dart';
import '../services/firestore_service.dart';
import 'price_provider.dart';
import 'service_providers.dart';

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
    this.storeNote = '',
    this.categories = const [],
    this.nearbyStores = const [],
    this.onlineStores = const [],
    this.isStoresLoading = false,
    this.storesError,
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
  final String storeNote;
  final List<CategoryModel> categories;
  final List<Store> nearbyStores;
  final List<Store> onlineStores;
  final bool isStoresLoading;
  final String? storesError;
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
    String? storeNote,
    List<CategoryModel>? categories,
    List<Store>? nearbyStores,
    List<Store>? onlineStores,
    bool? isStoresLoading,
    String? storesError,
    bool clearStoresError = false,
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
      storeNote: storeNote ?? this.storeNote,
      categories: categories ?? this.categories,
      nearbyStores: nearbyStores ?? this.nearbyStores,
      onlineStores: onlineStores ?? this.onlineStores,
      isStoresLoading: isStoresLoading ?? this.isStoresLoading,
      storesError: clearStoresError ? null : (storesError ?? this.storesError),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isNearbyMode => activeTab == 0;

  List<Store> get visibleStores {
    final source = isNearbyMode ? nearbyStores : onlineStores;
    final q = searchQuery.trim().toLowerCase();
    final filtered = searchQuery.trim().isEmpty
        ? source
        : source
            .where(
              (s) =>
                  s.name.toLowerCase().contains(q) ||
                  s.district.toLowerCase().contains(q) ||
                  s.neighborhood.toLowerCase().contains(q) ||
                  s.searchKeywords.any((k) => k.toLowerCase().contains(q)),
            )
            .toList(growable: false);

    final ordered = List<Store>.of(filtered)
      ..sort((a, b) => a.name.compareTo(b.name));

    return ordered.take(5).toList(growable: false);
  }
}

final addPriceProvider = StateNotifierProvider<AddPriceNotifier, AddPriceState>((ref) {
  return AddPriceNotifier(
    ref.read(firestoreServiceProvider),
  );
});

class AddPriceNotifier extends StateNotifier<AddPriceState> {
  AddPriceNotifier(this._firestore)
      : super(const AddPriceState()) {
    loadStoresAndCategories();
  }

  final FirestoreService _firestore;

  Timer? _productSearchDebounce;

  @override
  void dispose() {
    _productSearchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadStoresAndCategories() async {
    state = state.copyWith(
      isStoresLoading: true,
      clearStoresError: true,
    );
    try {
      final categories = await _firestore.getCategories().first;
      final stores = await _firestore.getAllStoresStream().first;

      final nearby = stores
          .where((s) => s.status == StoreStatus.active && !s.isOnline)
          .map(_mapStore)
          .toList(growable: false);
      final online = stores
          .where((s) => s.status == StoreStatus.active && s.isOnline)
          .map(_mapStore)
          .toList(growable: false);

      state = state.copyWith(
        categories: categories,
        nearbyStores: nearby,
        onlineStores: online,
        isStoresLoading: false,
        clearStoresError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isStoresLoading: false,
        storesError: e.toString(),
        nearbyStores: const [],
        onlineStores: const [],
      );
    }
  }

  Store _mapStore(StoreModel model) {
    return Store(
      id: model.id,
      name: model.displayName,
      type: model.isOnline ? 'online' : 'nearby',
      storeType: model.storeType,
      distanceMeters: null,
      logoUrl: model.displayName.isNotEmpty ? model.displayName[0].toUpperCase() : '?',
      subtitle: _buildStoreSubtitle(model),
      city: model.city,
      district: model.district,
      neighborhood: model.neighborhood,
      address: model.address,
      lat: model.lat,
      lng: model.lng,
      status: model.status,
      legacyIsOnline: model.legacyIsOnline,
      isTemporary: model.isTemporary,
      isRecurring: model.isRecurring,
      addressText: model.addressText,
      searchKeywords: model.searchKeywords,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  String? _buildStoreSubtitle(StoreModel model) {
    return model.isOnline ? 'Online' : 'Fiziksel Market';
  }

  void setPrice(String value) => state = state.copyWith(price: value);
  void setSearchQuery(String value) => state = state.copyWith(searchQuery: value);
  void setStoreNote(String value) => state = state.copyWith(storeNote: value);
  void setActiveTab(int value) =>
      state = state.copyWith(activeTab: value, clearSelectedStore: true);

  void setSelectedStore(Store store) => state = state.copyWith(
        selectedStore: store,
        selectedStoreId: store.id,
        selectedStoreName: store.name,
      );

  void setCategory(CategoryModel? value) {
    if (state.lockedCategoryByProduct) return;
    state = state.copyWith(
      selectedCategoryId: value?.id,
      selectedCategoryName: value?.title,
    );
  }

  void onProductInputChanged(String value) {
    _productSearchDebounce?.cancel();

    final normalizedInput = value.trim();
    final wasSelected = state.selectedProductId != null;
    final shouldClearSelection =
        wasSelected && normalizedInput.toLowerCase() != state.productName.trim().toLowerCase();

    state = state.copyWith(
      productName: value,
      productSuggestions: const [],
      clearBarcode: true,
      clearSelectedProduct: shouldClearSelection,
      selectedProductImageUrl:
          shouldClearSelection ? null : state.selectedProductImageUrl,
      lockedCategoryByProduct:
          shouldClearSelection ? false : state.lockedCategoryByProduct,
    );

    if (normalizedInput.isEmpty) {
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
        if (state.productName.trim().toLowerCase() != normalizedInput.toLowerCase()) {
          return;
        }
        state = state.copyWith(
          productSuggestions: results.take(5).toList(growable: false),
        );
      } catch (_) {
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
    return _firestore.getProduct(selectedProductId);
  }

  Future<void> submitPrice({required String userId}) async {
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
      final product = await _resolveProductByNameOrBarcode();
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
        storeLocation: null,
        userNote: state.storeNote.trim().isEmpty ? null : state.storeNote.trim(),
        barcode: state.barcode,
        userId: userId,
        userName: fallbackReporterName,
        createdByUid: userId,
        price: parsedPrice,
        branchStoreId: state.selectedStoreId!,
        priceSourceType: state.selectedStore?.isOnline == true ? 'online_store' : 'store',
        chainId: state.selectedStoreId,
        storeName: state.selectedStoreName,
        reportedAt: DateTime.now(),
        isPending: true,
        verificationStatus: 'unverified',
        status: 'active',
        reporterUid: userId,
        reporterName: fallbackReporterName,
        reporterIsAnonymous: reporterIsAnonymous,
      );

      await _firestore.addPriceReport(payload);

      state = state.copyWith(
        isLoading: false,
        price: '',
        productName: '',
        searchQuery: '',
        storeNote: '',
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
