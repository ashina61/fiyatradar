import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/price_report.dart';
import '../models/store.dart';
import '../services/price_report_api_service.dart';

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

final priceReportApiServiceProvider = Provider<PriceReportApiService>((ref) {
  return PriceReportApiService();
});

final addPriceProvider = StateNotifierProvider<AddPriceNotifier, AddPriceState>((ref) {
  return AddPriceNotifier(ref.read(priceReportApiServiceProvider));
});

class AddPriceNotifier extends StateNotifier<AddPriceState> {
  AddPriceNotifier(this._api) : super(const AddPriceState()) {
    loadStores();
  }

  final PriceReportApiService _api;

  static const _fallbackNearby = <Store>[
    Store(id: 'bim', name: 'BİM', type: 'nearby', distanceMeters: 150, logoUrl: 'B', subtitle: 'Cumhuriyet Mah.'),
    Store(id: 'a101', name: 'A101', type: 'nearby', distanceMeters: 230, logoUrl: 'A', subtitle: 'Atatürk Cad.'),
    Store(id: 'migros', name: 'Migros Jet', type: 'nearby', distanceMeters: 400, logoUrl: 'M', subtitle: 'Sahil Yolu'),
    Store(id: 'sok', name: 'ŞOK Market', type: 'nearby', distanceMeters: 550, logoUrl: 'Ş', subtitle: 'Merkez Sok.'),
  ];

  static const _fallbackOnline = <Store>[
    Store(id: 'trendyol', name: 'Trendyol Go', type: 'online', distanceMeters: 0, logoUrl: 'T', subtitle: 'Hızlı Teslimat'),
    Store(id: 'getir', name: 'Getir', type: 'online', distanceMeters: 0, logoUrl: 'G', subtitle: 'Dakikalar İçinde'),
  ];

  Future<void> loadStores() async {
    try {
      final nearby = await _api.fetchStores(type: 'nearby');
      final online = await _api.fetchStores(type: 'online');
      state = state.copyWith(nearbyStores: nearby, onlineStores: online, clearError: true);
    } catch (_) {
      state = state.copyWith(nearbyStores: _fallbackNearby, onlineStores: _fallbackOnline);
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
      await _api.submitPrice(report);
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
