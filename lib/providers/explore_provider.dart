import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../main.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../services/location_service.dart';
import 'price_provider.dart';
import 'product_provider.dart';

enum ExploreMode { nearby, online, drops }

class StorePrice {
  final String storeId;
  final String storeName;
  final String? logoUrl;
  final String? url;
  final double price;

  const StorePrice({
    required this.storeId,
    required this.storeName,
    required this.logoUrl,
    required this.url,
    required this.price,
  });
}

class ExploreFeedItem {
  final ProductModel product;
  final PriceModel price;
  final StoreModel? store;
  final double? distanceMeters;
  final double dropPercent;
  final List<StorePrice> onlineCheapest3;
  final bool isPrimaryOnlineCheapest;

  const ExploreFeedItem({
    required this.product,
    required this.price,
    required this.store,
    required this.distanceMeters,
    required this.dropPercent,
    required this.onlineCheapest3,
    required this.isPrimaryOnlineCheapest,
  });

  double get displayPrice => price.price;

  bool get isLocalStore => !_isOnlineStore;

  bool get _isOnlineStore {
    if (store == null) return false;
    return store!.lat == 0 && store!.lng == 0;
  }

  String get storeName {
    final fromPrice = price.storeName?.trim();
    if (fromPrice != null && fromPrice.isNotEmpty) return fromPrice;
    final fromStore = store?.displayName.trim();
    if (fromStore != null && fromStore.isNotEmpty) return fromStore;
    return 'Magaza';
  }

  String get locationLabel {
    final neighborhood = store?.neighborhood.trim();
    if (neighborhood != null && neighborhood.isNotEmpty) return neighborhood;

    final address = store?.address?.trim();
    if (address != null && address.isNotEmpty) {
      final parts = address
          .split(',')
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.take(2).join(', ');
      }
    }

    final district = store?.district.trim() ?? '';
    final city = store?.city.trim() ?? '';
    if (district.isNotEmpty && city.isNotEmpty) return '$district / $city';
    if (district.isNotEmpty) return district;
    if (city.isNotEmpty) return city;

    final storeLocation = price.storeLocation?.trim();
    if (storeLocation != null && storeLocation.isNotEmpty) {
      return storeLocation
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(2)
          .join(', ');
    }

    return '';
  }

  String? get distanceLabel {
    final distance = distanceMeters;
    if (distance == null) return null;
    if (distance < 1000) return '${distance.round()} m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  bool get isNearby => (distanceMeters ?? double.infinity) <= 30;

  String? get storeUrl {
    final raw = store?.address?.trim();
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    return null;
  }
}

class ExploreState {
  final bool loading;
  final String? error;
  final List<ExploreFeedItem> items;
  final LocationData? userLocation;
  final String selectedCategory;
  final String searchQuery;
  final List<String> categories;
  final ExploreMode selectedMode;
  final Map<String, List<StorePrice>> cheapestCache;

  const ExploreState({
    required this.loading,
    required this.error,
    required this.items,
    required this.userLocation,
    required this.selectedCategory,
    required this.searchQuery,
    required this.categories,
    required this.selectedMode,
    required this.cheapestCache,
  });

  const ExploreState.initial()
      : loading = true,
        error = null,
        items = const [],
        userLocation = null,
        selectedCategory = 'Tumu',
        searchQuery = '',
        categories = const ['Tumu', 'Temizlik', 'Kisisel Bakim', 'Kitap', 'Gida'],
        selectedMode = ExploreMode.nearby,
        cheapestCache = const {};

  ExploreState copyWith({
    bool? loading,
    String? error,
    bool clearError = false,
    List<ExploreFeedItem>? items,
    LocationData? userLocation,
    bool clearLocation = false,
    String? selectedCategory,
    String? searchQuery,
    List<String>? categories,
    ExploreMode? selectedMode,
    Map<String, List<StorePrice>>? cheapestCache,
  }) {
    return ExploreState(
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      userLocation: clearLocation ? null : (userLocation ?? this.userLocation),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      selectedMode: selectedMode ?? this.selectedMode,
      cheapestCache: cheapestCache ?? this.cheapestCache,
    );
  }
}

class ExploreController extends StateNotifier<ExploreState> {
  final Ref ref;

  List<ProductModel> _products = const [];
  List<PriceModel> _prices = const [];
  List<StoreModel> _stores = const [];

  ExploreController(this.ref) : super(const ExploreState.initial()) {
    _bindStreams();
  }

  void _bindStreams() {
    ref.listen<AsyncValue<List<ProductModel>>>(allProductsProvider, (_, next) {
      next.when(
        data: (data) {
          _products = data;
          _recompute();
        },
        loading: () => _setLoading(),
        error: (error, _) => _setError(error),
      );
    }, fireImmediately: true);

    ref.listen<AsyncValue<List<PriceModel>>>(exploreLatestPricesProvider, (_, next) {
      next.when(
        data: (data) {
          _prices = data;
          _recompute();
        },
        loading: () => _setLoading(),
        error: (error, _) => _setError(error),
      );
    }, fireImmediately: true);

    ref.listen<AsyncValue<List<StoreModel>>>(allStoresStreamProvider, (_, next) {
      next.when(
        data: (data) {
          _stores = data;
          _recompute();
        },
        loading: () {},
        error: (_, __) {},
      );
    }, fireImmediately: true);

    ref.listen<AsyncValue<LocationData?>>(currentLocationProvider, (_, next) {
      next.when(
        data: (location) {
          state = state.copyWith(userLocation: location);
          _recompute();
        },
        loading: () {},
        error: (_, __) {
          state = state.copyWith(clearLocation: true);
          _recompute();
        },
      );
    }, fireImmediately: true);

    ref.listen<AsyncValue<List<Map<String, dynamic>>>>(categoriesProvider, (_, next) {
      next.when(
        data: (data) {
          final dynamicCategories = data
              .map((category) => (category['name'] ?? '').toString().trim())
              .where((name) => name.isNotEmpty)
              .toList();
          final merged = <String>['Tumu', 'Temizlik', 'Kisisel Bakim', 'Kitap', 'Gida', ...dynamicCategories]
              .toSet()
              .toList();
          state = state.copyWith(categories: merged);
        },
        loading: () {},
        error: (_, __) {},
      );
    }, fireImmediately: true);
  }

  void _setLoading() {
    state = state.copyWith(loading: true, clearError: true);
  }

  void _setError(Object error) {
    state = state.copyWith(loading: false, error: error.toString());
  }

  void updateSearchQuery(String value) {
    state = state.copyWith(searchQuery: value, clearError: true);
    _recompute();
  }

  void updateCategory(String category) {
    state = state.copyWith(selectedCategory: category, clearError: true);
    _recompute();
  }

  void updateMode(ExploreMode mode) {
    state = state.copyWith(selectedMode: mode, clearError: true);
    _recompute();
  }

  void retry() {
    ref.invalidate(allProductsProvider);
    ref.invalidate(exploreLatestPricesProvider);
    ref.invalidate(allStoresStreamProvider);
    ref.invalidate(currentLocationProvider);
  }

  void _recompute() {
    final productMap = {for (final product in _products) product.id: product};
    final storeMap = {for (final store in _stores) store.id: store};
    final query = state.searchQuery.trim().toLowerCase();

    final pricesByProduct = <String, List<PriceModel>>{};
    for (final price in _prices) {
      pricesByProduct.putIfAbsent(price.productId, () => []).add(price);
    }

    final cheapestCache = <String, List<StorePrice>>{};
    for (final entry in pricesByProduct.entries) {
      final productPrices = entry.value.where((p) {
        final store = storeMap[p.branchStoreId];
        return _isOnlineStore(store);
      }).toList();

      if (productPrices.isEmpty) continue;

      productPrices.sort((a, b) => a.price.compareTo(b.price));
      cheapestCache[entry.key] = productPrices.take(3).map((price) {
        final store = storeMap[price.branchStoreId];
        return StorePrice(
          storeId: price.branchStoreId,
          storeName: price.storeName?.trim().isNotEmpty == true
              ? price.storeName!.trim()
              : (store?.displayName.trim().isNotEmpty == true ? store!.displayName.trim() : 'Magaza'),
          logoUrl: null,
          url: _onlineStoreUrl(store),
          price: price.price,
        );
      }).toList();
    }

    final items = _prices
        .map((price) {
          final product = productMap[price.productId];
          if (product == null) return null;

          if (state.selectedCategory != 'Tumu' && !product.categories.contains(state.selectedCategory)) {
            return null;
          }

          final store = storeMap[price.branchStoreId];
          if (state.selectedMode == ExploreMode.nearby && !_isLocalStore(store, price)) {
            return null;
          }
          if (state.selectedMode == ExploreMode.online && !_isOnlineStore(store)) {
            return null;
          }

          final searchable = [
            product.name,
            product.categories.join(' '),
            product.brand,
            price.storeName ?? '',
            store?.displayName ?? '',
          ].join(' ').toLowerCase();

          if (query.isNotEmpty && !searchable.contains(query)) {
            return null;
          }

          final dropPercent = _computeDropPercent(pricesByProduct[price.productId] ?? const [], price);
          if (state.selectedMode == ExploreMode.drops && dropPercent <= 0) {
            return null;
          }

          final onlineCheapest3 = cheapestCache[price.productId] ?? const [];
          return ExploreFeedItem(
            product: product,
            price: price,
            store: store,
            distanceMeters: _distanceFromUser(state.userLocation, store, price),
            dropPercent: dropPercent,
            onlineCheapest3: onlineCheapest3,
            isPrimaryOnlineCheapest: onlineCheapest3.isNotEmpty && onlineCheapest3.first.storeId == price.branchStoreId,
          );
        })
        .whereType<ExploreFeedItem>()
        .toList();

    _sortItems(items);

    state = state.copyWith(
      loading: false,
      clearError: true,
      items: items,
      cheapestCache: cheapestCache,
    );
  }

  void _sortItems(List<ExploreFeedItem> items) {
    if (state.selectedMode == ExploreMode.online) {
      items.sort((a, b) => a.displayPrice.compareTo(b.displayPrice));
      return;
    }

    if (state.selectedMode == ExploreMode.drops) {
      items.sort((a, b) => b.dropPercent.compareTo(a.dropPercent));
      return;
    }

    items.sort((a, b) {
      final ad = a.distanceMeters;
      final bd = b.distanceMeters;

      if (state.userLocation != null) {
        if (ad != null && bd != null) {
          final distanceCompare = ad.compareTo(bd);
          if (distanceCompare != 0) return distanceCompare;
          return b.price.createdAt.compareTo(a.price.createdAt);
        }
        if (ad != null) return -1;
        if (bd != null) return 1;
      }

      return b.price.createdAt.compareTo(a.price.createdAt);
    });
  }

  double _computeDropPercent(List<PriceModel> productPrices, PriceModel currentPrice) {
    if (productPrices.length < 2) return 0;
    final sorted = [...productPrices]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final currentIndex = sorted.indexWhere((p) => p.id == currentPrice.id);
    if (currentIndex < 0 || currentIndex == sorted.length - 1) return 0;

    final previous = sorted[currentIndex + 1];
    if (previous.price <= 0 || currentPrice.price >= previous.price) return 0;
    return ((previous.price - currentPrice.price) / previous.price) * 100;
  }

  bool _isLocalStore(StoreModel? store, PriceModel price) {
    if (store != null) return !_isOnlineStore(store);
    final point = price.geoPoint;
    return point != null && point.latitude != 0 && point.longitude != 0;
  }

  bool _isOnlineStore(StoreModel? store) {
    if (store == null) return false;
    return store.lat == 0 && store.lng == 0;
  }

  String? _onlineStoreUrl(StoreModel? store) {
    final address = store?.address?.trim();
    if (address == null || address.isEmpty) return null;
    if (address.startsWith('http://') || address.startsWith('https://')) return address;
    return null;
  }

  double? _distanceFromUser(LocationData? locationData, StoreModel? store, PriceModel price) {
    if (locationData == null) return null;

    final lat = store?.lat ?? price.geoPoint?.latitude;
    final lng = store?.lng ?? price.geoPoint?.longitude;
    if (lat == null || lng == null || lat == 0 || lng == 0) return null;

    return Geolocator.distanceBetween(
      locationData.geoPoint.latitude,
      locationData.geoPoint.longitude,
      lat,
      lng,
    );
  }
}

final exploreControllerProvider =
    StateNotifierProvider.autoDispose<ExploreController, ExploreState>((ref) {
  return ExploreController(ref);
});

final exploreLatestPricesProvider = StreamProvider<List<PriceModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getLatestPrices(limit: 60);
});
