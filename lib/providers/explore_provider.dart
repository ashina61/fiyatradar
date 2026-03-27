import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_init_provider.dart';
import '../models/price_model.dart';
import '../models/product_model.dart';
import '../models/store_model.dart';
import '../models/category_model.dart';
import '../services/location_service.dart';
import 'price_provider.dart';
import 'product_provider.dart' hide firestoreServiceProvider;

enum ExploreMode { nearby, online, drops }

const _allCategoriesLabel = 'Tumu';

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
  final double? priceChangePercent;
  final List<StorePrice> onlineCheapest3;
  final bool isPrimaryOnlineCheapest;
  final double recencyMinutes;
  final double distScore;
  final double dropScore;
  final double recencyScore;
  final double heatScore;

  const ExploreFeedItem({
    required this.product,
    required this.price,
    required this.store,
    required this.distanceMeters,
    required this.dropPercent,
    required this.priceChangePercent,
    required this.onlineCheapest3,
    required this.isPrimaryOnlineCheapest,
    required this.recencyMinutes,
    required this.distScore,
    required this.dropScore,
    required this.recencyScore,
    required this.heatScore,
  });

  double get displayPrice => price.price;

  bool get isLocalStore => !_isOnlineStore;
  bool get isNeighborhoodMarket => store?.isNeighborhoodMarket == true;
  bool get isNeighborhoodMarketOpenToday => store?.isOpenToday == true;

  bool get _isOnlineStore {
    if (store == null) return false;
    return store!.lat == 0 && store!.lng == 0;
  }

  String get storeName {
    final fromPrice = price.storeName?.trim();
    if (fromPrice != null && fromPrice.isNotEmpty) return fromPrice;
    final fromStore = store?.displayName.trim();
    if (fromStore != null && fromStore.isNotEmpty) return fromStore;
    final fromSelectedStore = price.selectedStoreId?.trim();
    if (fromSelectedStore != null && fromSelectedStore.isNotEmpty) {
      return fromSelectedStore;
    }
    final fromBranch = price.branchStoreId.trim();
    if (fromBranch.isNotEmpty) return fromBranch;
    return 'Market';
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

  String? get neighborhoodMarketScheduleLabel {
    if (!isNeighborhoodMarket) return null;
    final days = store?.activeDays ?? const [];
    if (days.isEmpty) return null;
    final day = _weekdayTr(days.first);
    final start = store?.startHour?.trim();
    final end = store?.endHour?.trim();
    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '$day • $start–$end';
    }
    return day;
  }

  static String _weekdayTr(String key) {
    switch (key) {
      case 'monday':
        return 'Pazartesi';
      case 'tuesday':
        return 'Salı';
      case 'wednesday':
        return 'Çarşamba';
      case 'thursday':
        return 'Perşembe';
      case 'friday':
        return 'Cuma';
      case 'saturday':
        return 'Cumartesi';
      case 'sunday':
        return 'Pazar';
      default:
        return key;
    }
  }

  String get neighborhoodLabel {
    final rawNeighborhood = store?.neighborhood.trim();
    if (rawNeighborhood == null || rawNeighborhood.isEmpty) return '—';

    final normalized = rawNeighborhood.toLowerCase();
    if (normalized.endsWith('mah.') || normalized.endsWith('mah')) {
      return rawNeighborhood;
    }

    return '$rawNeighborhood mah.';
  }

  String? get distanceLabel {
    final distance = distanceMeters;
    if (distance == null) return null;
    if (distance < 1000) return '${distance.round()}m';
    return '${(distance / 1000).toStringAsFixed(1)} km';
  }

  bool get isNearby => (distanceMeters ?? double.infinity) <= 30;

  bool get isVeryNearby => (distanceMeters ?? double.infinity) <= 100;

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
        selectedCategory = _allCategoriesLabel,
        searchQuery = '',
        categories = const [_allCategoriesLabel],
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

    ref.listen<AsyncValue<List<CategoryModel>>>(categoriesProvider, (_, next) {
      next.when(
        data: (data) {
          final dynamicCategories = data
              .map((category) => category.name.trim())
              .where((name) => name.isNotEmpty)
              .toList();
          final merged = <String>[_allCategoriesLabel, ...dynamicCategories]
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
              : (store?.displayName.trim().isNotEmpty == true
                  ? store!.displayName.trim()
                  : (price.selectedStoreId?.trim().isNotEmpty == true
                      ? price.selectedStoreId!.trim()
                      : (price.branchStoreId.trim().isNotEmpty ? price.branchStoreId.trim() : 'Market'))),
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

          if (!_matchesCategoryFilter(product.categories, state.selectedCategory)) {
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
            store?.neighborhood ?? '',
            store?.district ?? '',
            ...(store?.searchKeywords ?? const <String>[]),
          ].join(' ').toLowerCase();

          if (query.isNotEmpty && !searchable.contains(query)) {
            return null;
          }

          final dropPercent = _computeDropPercent(pricesByProduct[price.productId] ?? const [], price);
          if (state.selectedMode == ExploreMode.drops && dropPercent <= 0) {
            return null;
          }

          final distanceMeters = _distanceFromUser(state.userLocation, store, price);
          final recencyMinutes = DateTime.now().difference(price.createdAt).inMinutes.toDouble();
          final distScore = _clamp01(1 - ((distanceMeters ?? 999999) / 2000));
          final dropScore = _clamp01(dropPercent / 30);
          final recencyScore = _clamp01(1 - (recencyMinutes / 1440));
          final heatScore = (0.55 * distScore) + (0.30 * dropScore) + (0.15 * recencyScore);
          final isOpenTodayMarket = store?.isOpenToday == true;
          final adjustedHeatScore = isOpenTodayMarket ? heatScore + 0.25 : heatScore;

          final onlineCheapest3 = cheapestCache[price.productId] ?? const [];
          return ExploreFeedItem(
            product: product,
            price: price,
            store: store,
            distanceMeters: distanceMeters,
            dropPercent: dropPercent,
            priceChangePercent: _computeSignedPriceChangePercent(
              pricesByProduct[price.productId] ?? const [],
              price,
            ),
            onlineCheapest3: onlineCheapest3,
            isPrimaryOnlineCheapest: onlineCheapest3.isNotEmpty && onlineCheapest3.first.storeId == price.branchStoreId,
            recencyMinutes: recencyMinutes,
            distScore: distScore,
            dropScore: dropScore,
            recencyScore: recencyScore,
            heatScore: adjustedHeatScore,
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
      items.sort((a, b) {
        final dropCompare = b.dropScore.compareTo(a.dropScore);
        if (dropCompare != 0) return dropCompare;
        final recencyCompare = b.recencyScore.compareTo(a.recencyScore);
        if (recencyCompare != 0) return recencyCompare;
        return a.product.name.toLowerCase().compareTo(b.product.name.toLowerCase());
      });
      return;
    }

    if (state.selectedMode == ExploreMode.drops) {
      items.sort((a, b) {
        final dropCompare = b.dropScore.compareTo(a.dropScore);
        if (dropCompare != 0) return dropCompare;
        return b.distScore.compareTo(a.distScore);
      });
      return;
    }

    items.sort((a, b) => b.heatScore.compareTo(a.heatScore));
  }

  double _clamp01(double value) => value.clamp(0, 1).toDouble();

  double _computeDropPercent(List<PriceModel> productPrices, PriceModel currentPrice) {
    if (productPrices.length < 2) return 0;
    final sorted = [...productPrices]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final currentIndex = sorted.indexWhere((p) => p.id == currentPrice.id);
    if (currentIndex < 0 || currentIndex == sorted.length - 1) return 0;

    final previous = sorted[currentIndex + 1];
    if (previous.price <= 0 || currentPrice.price >= previous.price) return 0;
    return ((previous.price - currentPrice.price) / previous.price) * 100;
  }

  double? _computeSignedPriceChangePercent(
    List<PriceModel> productPrices,
    PriceModel currentPrice,
  ) {
    if (productPrices.length < 2) return null;
    final sorted = [...productPrices]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final currentIndex = sorted.indexWhere((p) => p.id == currentPrice.id);
    if (currentIndex < 0 || currentIndex == sorted.length - 1) return null;

    final previous = sorted[currentIndex + 1];
    if (previous.price <= 0) return null;

    final percent = ((currentPrice.price - previous.price) / previous.price) * 100;
    if (percent.abs() < 0.5) return null;
    return percent;
  }

  bool _isLocalStore(StoreModel? store, PriceModel price) {
    if (store != null) return !store.isOnline;
    final point = price.geoPoint;
    return point != null && point.latitude != 0 && point.longitude != 0;
  }

  bool _isOnlineStore(StoreModel? store) {
    if (store == null) return false;
    return store.isOnline;
  }

  String? _onlineStoreUrl(StoreModel? store) {
    final address = store?.address?.trim();
    if (address == null || address.isEmpty) return null;
    if (address.startsWith('http://') || address.startsWith('https://')) return address;
    return null;
  }

  double? _distanceFromUser(LocationData? locationData, StoreModel? store, PriceModel price) {
    if (locationData == null) return null;

    final userLat = locationData.geoPoint.latitude;
    final userLng = locationData.geoPoint.longitude;

    final storeLat = store?.lat;
    final storeLng = store?.lng;
    final hasStoreCoordinates =
        storeLat != null && storeLng != null && storeLat != 0 && storeLng != 0;

    final lat = hasStoreCoordinates ? storeLat : price.geoPoint?.latitude;
    final lng = hasStoreCoordinates ? storeLng : price.geoPoint?.longitude;
    if (lat == null || lng == null || lat == 0 || lng == 0) {
      if (kDebugMode) {
        debugPrint(
          'DISTANCE user=($userLat,$userLng) store=${store?.id ?? price.branchStoreId} location=(null) meters=null',
        );
      }
      return null;
    }

    final meters = _haversineMeters(userLat, userLng, lat, lng);
    if (kDebugMode) {
      debugPrint(
        'DISTANCE user=($userLat,$userLng) store=${store?.id ?? price.branchStoreId} location=($lat,$lng) meters=${meters.toStringAsFixed(2)}',
      );
    }
    return meters;
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
    final startLatRad = _degToRad(startLatitude);
    final endLatRad = _degToRad(endLatitude);

    final a =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(startLatRad) *
            math.cos(endLatRad) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2));
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _degToRad(double degrees) => degrees * (math.pi / 180);
}

bool _matchesCategoryFilter(List<String> productCategories, String selectedCategory) {
  if (_isAllCategoriesSelected(selectedCategory)) {
    return true;
  }

  if (productCategories.isEmpty) {
    return false;
  }

  final normalizedSelected = _normalizeCategory(selectedCategory);
  if (normalizedSelected.isEmpty) {
    return false;
  }

  return productCategories
      .map(_normalizeCategory)
      .any((category) => category == normalizedSelected);
}

bool _isAllCategoriesSelected(String value) => _normalizeCategory(value) == _normalizeCategory(_allCategoriesLabel);

String _normalizeCategory(String value) {
  final lower = value.trim().toLowerCase();
  if (lower.isEmpty) return '';

  return lower
      .replaceAll('ı', 'i')
      .replaceAll('İ', 'i')
      .replaceAll('ş', 's')
      .replaceAll('Ş', 's')
      .replaceAll('ğ', 'g')
      .replaceAll('Ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('Ü', 'u')
      .replaceAll('ö', 'o')
      .replaceAll('Ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll('Ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ');
}

final exploreControllerProvider =
    StateNotifierProvider.autoDispose<ExploreController, ExploreState>((ref) {
  return ExploreController(ref);
});

final exploreLatestPricesProvider = StreamProvider<List<PriceModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getLatestPrices(limit: 60);
});
