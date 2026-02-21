import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_report.dart';
import '../models/store.dart';
import '../services/store_service.dart';

class AddPriceState {
  const AddPriceState({
    this.price = '',
    this.productName = '',
    this.barcode,
    this.selectedCategory,
    this.activeTab = 0,
    this.searchQuery = '',
    this.selectedStore,
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
  final String? selectedCategory;
  final int activeTab;
  final String searchQuery;
  final Store? selectedStore;
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
    String? selectedCategory,
    bool clearCategory = false,
    int? activeTab,
    String? searchQuery,
    Store? selectedStore,
    bool clearSelectedStore = false,
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
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedStore: clearSelectedStore ? null : (selectedStore ?? this.selectedStore),
      nearbyStores: nearbyStores ?? this.nearbyStores,
      onlineStores: onlineStores ?? this.onlineStores,
      isStoresLoading: isStoresLoading ?? this.isStoresLoading,
      storesError: clearStoresError ? null : (storesError ?? this.storesError),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  List<Store> get visibleStores {
    final source = activeTab == 0 ? nearbyStores : onlineStores;
    if (searchQuery.trim().isEmpty) return source;
    final q = searchQuery.toLowerCase();
    return source.where((s) => s.name.toLowerCase().contains(q)).toList(growable: false);
  }
}

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});

final addPriceProvider = StateNotifierProvider<AddPriceNotifier, AddPriceState>((ref) {
  return AddPriceNotifier(ref.read(storeServiceProvider));
});

class AddPriceNotifier extends StateNotifier<AddPriceState> {
  AddPriceNotifier(this._service) : super(const AddPriceState()) {
    loadStores();
  }

  final StoreService _service;

  Future<void> loadStores() async {
    state = state.copyWith(isStoresLoading: true, clearStoresError: true);
    try {
      final nearby = await _service.fetchStores(type: 'nearby');
      final online = await _service.fetchStores(type: 'online');
      state = state.copyWith(
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

  void setPrice(String value) => state = state.copyWith(price: value);
  void setProductName(String value) => state = state.copyWith(productName: value);
  void setCategory(String? value) => state = state.copyWith(selectedCategory: value);
  void setSearchQuery(String value) => state = state.copyWith(searchQuery: value);
  void setActiveTab(int value) => state = state.copyWith(activeTab: value, clearSelectedStore: true);
  void setSelectedStore(Store store) => state = state.copyWith(selectedStore: store);
  void setBarcode(String? value) => state = state.copyWith(barcode: value);

  Future<void> submitPrice({required String userId}) async {
    final price = double.tryParse(state.price.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      throw Exception('Lütfen geçerli bir fiyat girin.');
    }
    if (state.productName.trim().isEmpty) {
      throw Exception('Lütfen ürün adını girin.');
    }
    if (state.selectedCategory == null) {
      throw Exception('Lütfen kategori seçin.');
    }
    if (state.selectedStore == null) {
      throw Exception('Lütfen bir mağaza seçin.');
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final report = PriceReport(
        productName: state.productName.trim(),
        category: state.selectedCategory!,
        price: price,
        storeId: state.selectedStore!.id,
        storeType: state.selectedStore!.type,
        userId: userId,
        barcode: state.barcode,
      );
      await _service.submitPrice(report);
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
