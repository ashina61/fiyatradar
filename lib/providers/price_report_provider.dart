import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category_model.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store.dart';
import '../models/store_model.dart';
import '../services/firestore_service.dart';
import 'product_provider.dart';

class AddPriceState {
  const AddPriceState({
    this.price = '',
    this.productName = '',
    this.barcode,
    this.selectedCategoryId,
    this.selectedCategoryName,
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
    this.isLoading = false,
    this.error,
  });

  final String price;
  final String productName;
  final String? barcode;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
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
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isNearbyMode => activeTab == 0;

  List<Store> get visibleStores {
    final source = isNearbyMode ? nearbyStores : onlineStores;
    if (searchQuery.trim().isEmpty) return source;
    final q = searchQuery.toLowerCase();
    return source.where((s) => s.name.toLowerCase().contains(q)).toList(growable: false);
  }
}

final addPriceProvider = StateNotifierProvider<AddPriceNotifier, AddPriceState>((ref) {
  return AddPriceNotifier(ref.read(firestoreServiceProvider));
});

class AddPriceNotifier extends StateNotifier<AddPriceState> {
  AddPriceNotifier(this._firestore) : super(const AddPriceState()) {
    loadStoresAndCategories();
  }

  final FirestoreService _firestore;

  Future<void> loadStoresAndCategories() async {
    state = state.copyWith(isStoresLoading: true, clearStoresError: true);
    try {
      debugPrint('[AddPrice] Firestore query: categories');
      debugPrint('[AddPrice] Firestore query: stores');

      final categories = await _firestore.getCategories().first;
      final stores = await _firestore.getAllStoresStream().first;

      final nearby = stores.where((s) => s.status == StoreStatus.active && !s.isOnline).map(_mapStore).toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));
      final online = stores.where((s) => s.status == StoreStatus.active && s.isOnline).map(_mapStore).toList(growable: false)
        ..sort((a, b) => a.name.compareTo(b.name));

      if (categories.isNotEmpty) {
        final sample = categories.first;
        debugPrint('[AddPrice] Category mapped fields: id=${sample.id}, title=${sample.title}, isActive=${sample.isActive}');
      }
      if (stores.isNotEmpty) {
        final sample = stores.first;
        debugPrint('[AddPrice] Store mapped fields: id=${sample.id}, displayName=${sample.displayName}, type=${sample.type.name}, status=${sample.status.name}, lat=${sample.lat}, lng=${sample.lng}');
      }

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
    final distanceMeters = (model.lat == 0 || model.lng == 0) ? 0 : 1;
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

  void setPrice(String value) => state = state.copyWith(price: value);
  void setProductName(String value) => state = state.copyWith(productName: value);
  void setCategory(CategoryModel? value) => state = state.copyWith(
        selectedCategoryId: value?.id,
        selectedCategoryName: value?.title,
      );
  void setSearchQuery(String value) => state = state.copyWith(searchQuery: value);
  void setActiveTab(int value) => state = state.copyWith(activeTab: value, clearSelectedStore: true);
  void setSelectedStore(Store store) => state = state.copyWith(
        selectedStore: store,
        selectedStoreId: store.id,
        selectedStoreName: store.name,
      );
  void setBarcode(String? value) => state = state.copyWith(barcode: value);

  Future<ProductModel?> _resolveProductByNameOrBarcode() async {
    final byBarcode = state.barcode?.trim() ?? '';
    final query = byBarcode.isNotEmpty ? byBarcode : state.productName.trim();
    if (query.isEmpty) return null;

    debugPrint('[AddPrice] Firestore query: products (search="$query")');
    final matches = await _firestore.searchProducts(query);
    if (matches.isEmpty) return null;

    final normalizedName = state.productName.trim().toLowerCase();
    for (final product in matches) {
      if (product.name.trim().toLowerCase() == normalizedName && normalizedName.isNotEmpty) {
        return product;
      }
    }
    return matches.first;
  }

  Future<void> submitPrice({required String userId}) async {
    final parsedPrice = double.tryParse(state.price.replaceAll(',', '.'));
    if (parsedPrice == null || parsedPrice <= 0) {
      throw Exception('Lütfen geçerli bir fiyat girin.');
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

      final payload = PriceModel(
        id: '',
        productId: product.id,
        productName: product.name,
        barcode: state.barcode,
        userId: userId,
        createdByUid: userId,
        price: parsedPrice,
        branchStoreId: state.selectedStoreId!,
        chainId: null,
        storeName: state.selectedStoreName,
        reportedAt: DateTime.now(),
        isPending: true,
        verificationStatus: 'unverified',
        status: 'active',
      );

      debugPrint('[AddPrice] Firestore write target: priceReports + price_entries + price_dedupes');
      debugPrint('[AddPrice] Submit payload => ${payload.toFirestore()}');

      await _firestore.addPriceReport(payload);

      state = state.copyWith(
        isLoading: false,
        price: '',
        productName: '',
        searchQuery: '',
        clearCategory: true,
        clearSelectedStore: true,
        clearBarcode: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}
