import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/basket_item_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../models/store_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/cart_comparison_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'basket_pricing.dart';
import 'cart_comparison_state.dart';
import 'basket_repository.dart';

class BasketEstimatedTotal {
  const BasketEstimatedTotal({
    required this.total,
    required this.missingPriceCount,
  });

  final double total;
  final int missingPriceCount;

  bool get hasMissingPrices => missingPriceCount > 0;
}

class BasketViewModel extends ChangeNotifier {
  BasketViewModel({
    required this.firestoreService,
    required this.repository,
    required this.locationService,
    this.comparisonService = const CartComparisonService(),
  });

  final FirestoreService firestoreService;
  final BasketRepository repository;
  final LocationService locationService;
  final CartComparisonService comparisonService;

  StreamSubscription<List<Map<String, dynamic>>>? _basketSubscription;
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  String? userId;
  bool isLoadingItems = false;
  bool isCalculating = false;
  String? errorMessage;

  List<BasketItemModel> items = [];
  Map<String, ProductModel> productMap = {};
  BasketPricingSummary? pricingSummary;
  CartComparisonResult? comparisonResult;
  CartComparisonState comparisonState = const CartComparisonState.idle();
  Map<String, PriceModel?> latestProductPrices = {};
  Set<String> unverifiedPriceItemKeys = {};
  bool hasLocationPermission = false;
  String? calculationNotice;
  Map<String, String> marketNames = {};
  int lastPriceDocumentCount = 0;
  List<StoreModel> availableStores = [];
  Set<String> selectedStoreIds = <String>{};
  List<String> missingPriceProducts = const <String>[];
  final Set<String> _inFlightLastPriceFetches = <String>{};
  final Set<String> _resolvedLastPriceFetches = <String>{};

  void setUser(String? nextUserId) {
    if (userId == nextUserId) return;
    userId = nextUserId;
    _basketSubscription?.cancel();
    _productsSubscription?.cancel();
    items = [];
    productMap = {};
    pricingSummary = null;
    comparisonResult = null;
    latestProductPrices = {};
    unverifiedPriceItemKeys = {};
    hasLocationPermission = false;
    calculationNotice = null;
    marketNames = {};
    lastPriceDocumentCount = 0;
    availableStores = [];
    selectedStoreIds = <String>{};
    missingPriceProducts = const <String>[];
    _inFlightLastPriceFetches.clear();
    _resolvedLastPriceFetches.clear();
    errorMessage = null;
    comparisonState = const CartComparisonState.idle();
    if (userId == null) {
      notifyListeners();
      return;
    }

    isLoadingItems = true;
    notifyListeners();
    _basketSubscription = firestoreService.getBasketItems(userId!).listen(
      (rawItems) {
        items = rawItems.map(BasketItemModel.fromFirestore).toList();
        _subscribeProducts();
        _syncLastKnownPricesForItems();
        isLoadingItems = false;
        notifyListeners();
      },
      onError: (error) {
        isLoadingItems = false;
        if (error is FirebaseException && error.code == 'permission-denied') {
          errorMessage = 'Sepet icin erisim izni bulunamadi.';
        } else {
          errorMessage = 'Sepet yuklenemedi. Lutfen tekrar deneyin.';
        }
        notifyListeners();
      },
    );
  }

  void _subscribeProducts() {
    _productsSubscription?.cancel();
    _productsSubscription = firestoreService.getAllProducts().listen(
      (products) {
        final ids = items.map((item) => item.productId).toSet();
        productMap = {
          for (final product in products)
            if (ids.contains(product.id)) product.id: product,
        };
        notifyListeners();
      },
      onError: (_) {
        errorMessage = 'Urun bilgileri alinamadi.';
        notifyListeners();
      },
    );
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (userId == null) return;
    if (quantity <= 0) {
      await firestoreService.removeBasketItem(
        userId: userId!,
        productId: productId,
      );
      return;
    }
    await firestoreService.upsertBasketItem(
      userId: userId!,
      productId: productId,
      quantity: quantity,
    );
  }


  BasketEstimatedTotal get computedEstimatedTotal {
    var total = 0.0;
    var missing = 0;

    for (final item in items) {
      final unitPrice = item.lastKnownPrice;
      if (unitPrice == null) {
        missing += 1;
        continue;
      }
      total += item.quantity * unitPrice;
    }

    return BasketEstimatedTotal(total: total, missingPriceCount: missing);
  }

  void _syncLastKnownPricesForItems() {
    final activeProductIds = items.map((item) => item.productId).toSet();
    _inFlightLastPriceFetches.removeWhere((id) => !activeProductIds.contains(id));
    _resolvedLastPriceFetches.removeWhere((id) => !activeProductIds.contains(id));

    for (final item in items) {
      if (item.lastKnownPrice != null) {
        _resolvedLastPriceFetches.add(item.productId);
        continue;
      }
      if (_resolvedLastPriceFetches.contains(item.productId)) continue;
      _fetchLastPriceForItem(item.productId);
    }
  }

  Future<void> _fetchLastPriceForItem(String productId) async {
    if (_inFlightLastPriceFetches.contains(productId)) return;
    _inFlightLastPriceFetches.add(productId);

    try {
      final price = await repository.fetchLastPrice(productId);
      if (userId == null) return;

      final index = items.indexWhere((item) => item.productId == productId);
      if (index == -1) return;

      final current = items[index];
      final fetchedPrice = price?.price;
      if (current.lastKnownPrice == fetchedPrice) {
        _resolvedLastPriceFetches.add(productId);
        return;
      }

      await firestoreService.upsertBasketItem(
        userId: userId!,
        productId: productId,
        quantity: current.quantity,
        lastKnownPrice: fetchedPrice,
        includeLastKnownPrice: true,
      );
      _resolvedLastPriceFetches.add(productId);
    } finally {
      _inFlightLastPriceFetches.remove(productId);
    }
  }


  List<StoreModel> get nearbyStores =>
      availableStores.where((store) => !store.isOnline).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<StoreModel> get onlineStores =>
      availableStores.where((store) => store.isOnline).toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));

  List<String> get selectedStoreNames {
    if (selectedStoreIds.isEmpty) return const <String>[];
    final selected = availableStores
        .where((store) => selectedStoreIds.contains(store.id))
        .map((store) => store.displayName)
        .toList()
      ..sort();
    return selected;
  }

  Future<void> loadStoresIfNeeded() async {
    if (availableStores.isNotEmpty) return;
    final stores = await firestoreService.getAllStoresStream().first;
    availableStores = stores;
    notifyListeners();
  }

  void setSelectedStoreIds(Set<String> ids) {
    selectedStoreIds = ids;
    notifyListeners();
  }

  Future<void> addProduct(String productId) async {
    final existing = items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => BasketItemModel(productId: '', quantity: 0),
    );
    final nextQty = existing.productId.isEmpty ? 1 : existing.quantity + 1;
    await updateQuantity(productId, nextQty);
    if (existing.productId.isEmpty) {
      unawaited(_fetchLastPriceForItem(productId));
    }
  }

  Future<void> calculate() async {
    if (userId == null || items.isEmpty) return;
    isCalculating = true;
    errorMessage = null;
    calculationNotice = null;
    comparisonState = comparisonState.copyWith(
      status: CartComparisonStatus.loading,
      topMarkets: const [],
      missingProducts: const [],
      clearBestMarket: true,
      clearNearestMarket: true,
      clearErrorMessage: true,
      clearEmptyReason: true,
    );
    notifyListeners();

    final descriptors = items
        .map((item) => BasketItemDescriptor(
              key: item.productId,
              productId: item.productId,
            ))
        .toList();

    try {
      await loadStoresIfNeeded();
      final fetchResult = await repository.fetchPricesForBasketItems(
        descriptors,
        allowedStoreIds: selectedStoreIds.isEmpty ? null : selectedStoreIds,
      );
      lastPriceDocumentCount = fetchResult.priceDocumentCount;
      marketNames = fetchResult.marketNames;

      final pricesIndex = {
        for (final entry in fetchResult.latestPricesByItem.entries)
          entry.key: {
            for (final priceEntry in entry.value.entries)
              priceEntry.key: priceEntry.value.price,
          },
      };

      pricingSummary = calculateBasketPricing(
        items: items
            .map(
              (item) => BasketItemInput(
                key: item.productId,
                name: productMap[item.productId]?.name ?? 'Urun',
                quantity: item.quantity,
              ),
            )
            .toList(),
        pricesIndex: pricesIndex,
        marketNames: fetchResult.marketNames,
      );

      missingPriceProducts = pricingSummary!.mixedResult.missingKeys
          .map((key) => productMap[key]?.name ?? 'Ürün')
          .toList();

      latestProductPrices = comparisonService.buildLatestProductPrices(
        items: items,
        latestPricesByItem: fetchResult.latestPricesByItem,
      );
      unverifiedPriceItemKeys = fetchResult.unverifiedPriceItemKeys;

      final stores = availableStores;
      final position = await locationService.getCurrentPosition();
      hasLocationPermission = position != null;
      comparisonResult = comparisonService.compare(
        items: items,
        productMap: productMap,
        latestPricesByItem: fetchResult.latestPricesByItem,
        marketNames: marketNames,
        stores: stores,
        userPosition: position,
        allowedMarketIds: selectedStoreIds.isEmpty ? null : selectedStoreIds,
      );
      calculationNotice = comparisonResult?.notice;

      final allMissingProducts = items
          .where((item) => (fetchResult.latestPricesByItem[item.productId] ?? const {}).isEmpty)
          .map((item) => productMap[item.productId]?.name ?? 'Ürün')
          .toList();

      final topMarkets = comparisonResult!.sortedMarkets
          .take(5)
          .map(CartMarketResultSummary.fromComparison)
          .toList();

      if (comparisonResult!.bestMarket == null) {
        comparisonState = CartComparisonState(
          status: CartComparisonStatus.empty,
          topMarkets: topMarkets,
          missingProducts: allMissingProducts,
          emptyReason: comparisonResult!.sortedMarkets.isEmpty
              ? 'Bu sepet için yeterli fiyat verisi yok.'
              : 'Marketlerde tüm ürünleri karşılayacak fiyat bulunamadı.',
        );
      } else {
        comparisonState = CartComparisonState(
          status: CartComparisonStatus.success,
          bestMarket: CartMarketResultSummary.fromComparison(comparisonResult!.bestMarket!),
          topMarkets: topMarkets,
          nearestMarket: comparisonResult!.nearestMarket != null
              ? CartMarketResultSummary.fromComparison(comparisonResult!.nearestMarket!)
              : null,
          missingProducts: allMissingProducts,
        );
      }
    } catch (error) {
      if (error is FirebaseException &&
          (error.code == 'permission-denied' || error.code == 'unauthenticated')) {
        errorMessage = 'Fiyatlar icin erisim izni bulunamadi.';
      } else if (error is FirebaseException && error.code == 'unavailable') {
        errorMessage = 'Baglanti hatasi. Lutfen internetinizi kontrol edin.';
      } else {
        errorMessage = 'Fiyat hesaplanamadi. Lutfen tekrar deneyin.';
      }
      comparisonState = CartComparisonState(
        status: CartComparisonStatus.error,
        errorMessage: errorMessage,
      );
    } finally {
      isCalculating = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _basketSubscription?.cancel();
    _productsSubscription?.cancel();
    super.dispose();
  }
}

final basketViewModelProvider =
    ChangeNotifierProvider.autoDispose<BasketViewModel>((ref) {
  final firestore = ref.watch(firestoreServiceProvider);
  final viewModel = BasketViewModel(
    firestoreService: firestore,
    repository: BasketRepository(),
    locationService: LocationService(),
  );

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    viewModel.setUser(next.value?.uid);
  });

  viewModel.setUser(ref.read(authStateProvider).value?.uid);
  return viewModel;
});
