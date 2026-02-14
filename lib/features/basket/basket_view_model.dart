import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/basket_item_model.dart';
import '../../models/price_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/cart_comparison_service.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import 'basket_pricing.dart';
import 'basket_repository.dart';

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
  Map<String, PriceModel?> latestProductPrices = {};
  Set<String> unverifiedPriceItemKeys = {};
  bool hasLocationPermission = false;
  String? calculationNotice;
  Map<String, String> marketNames = {};
  int lastPriceDocumentCount = 0;

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
    errorMessage = null;
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

  Future<void> addProduct(String productId) async {
    final existing = items.firstWhere(
      (item) => item.productId == productId,
      orElse: () => BasketItemModel(productId: '', quantity: 0),
    );
    final nextQty = existing.productId.isEmpty ? 1 : existing.quantity + 1;
    await updateQuantity(productId, nextQty);
  }

  Future<void> calculate() async {
    if (userId == null || items.isEmpty) return;
    isCalculating = true;
    errorMessage = null;
    calculationNotice = null;
    notifyListeners();

    final descriptors = items
        .map((item) => BasketItemDescriptor(
              key: item.productId,
              productId: item.productId,
            ))
        .toList();

    try {
      final fetchResult = await repository.fetchPricesForBasketItems(descriptors);
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

      latestProductPrices = comparisonService.buildLatestProductPrices(
        items: items,
        latestPricesByItem: fetchResult.latestPricesByItem,
      );
      unverifiedPriceItemKeys = fetchResult.unverifiedPriceItemKeys;

      final stores = await firestoreService.getAllStoresStream().first;
      final position = await locationService.getCurrentPosition();
      hasLocationPermission = position != null;
      comparisonResult = comparisonService.compare(
        items: items,
        productMap: productMap,
        latestPricesByItem: fetchResult.latestPricesByItem,
        marketNames: marketNames,
        stores: stores,
        userPosition: position,
      );
      calculationNotice = comparisonResult?.notice;
      if (calculationNotice == null && unverifiedPriceItemKeys.isNotEmpty) {
        calculationNotice = 'Bazı fiyatlar doğrulanmamış kaynaklardan getirildi.';
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
