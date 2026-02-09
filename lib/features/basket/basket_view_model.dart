import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/basket_item_model.dart';
import '../../models/product_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../services/firestore_service.dart';
import 'basket_pricing.dart';
import 'basket_repository.dart';

class BasketViewModel extends ChangeNotifier {
  BasketViewModel({
    required this.firestoreService,
    required this.repository,
  });

  final FirestoreService firestoreService;
  final BasketRepository repository;

  StreamSubscription<List<Map<String, dynamic>>>? _basketSubscription;
  StreamSubscription<List<ProductModel>>? _productsSubscription;

  String? userId;
  bool isLoadingItems = false;
  bool isCalculating = false;
  String? errorMessage;

  List<BasketItemModel> items = [];
  Map<String, ProductModel> productMap = {};
  BasketPricingSummary? pricingSummary;
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
    notifyListeners();

    final descriptors = items.map((item) {
      final product = productMap[item.productId];
      final barcode = product?.barcode?.trim();
      final name = product?.name.trim();
      return BasketItemDescriptor(
        key: _itemKey(item, product),
        productId: item.productId,
        barcode: barcode != null && barcode.isNotEmpty ? barcode : null,
        name: name != null && name.isNotEmpty ? name : null,
        normalizedName: name != null && name.isNotEmpty ? _normalizeName(name) : null,
      );
    }).toList();

    debugPrint('[BasketPricing] items keys: ${descriptors.map((e) => e.key).join(', ')}');

    try {
      final fetchResult = await repository.fetchPricesForBasketItems(descriptors);
      lastPriceDocumentCount = fetchResult.priceDocumentCount;
      marketNames = fetchResult.marketNames;
      debugPrint('[BasketPricing] firestore price docs: ${fetchResult.priceDocumentCount}');

      final inputs = items.map((item) {
        final product = productMap[item.productId];
        return BasketItemInput(
          key: _itemKey(item, product),
          name: product?.name ?? 'Urun',
          quantity: item.quantity,
        );
      }).toList();

      pricingSummary = calculateBasketPricing(
        items: inputs,
        pricesIndex: fetchResult.pricesIndex,
        marketNames: fetchResult.marketNames,
      );

      for (final descriptor in descriptors) {
        final count = fetchResult.pricesIndex[descriptor.key]?.length ?? 0;
        debugPrint('[BasketPricing] item ${descriptor.key} -> $count market');
      }

      final missing = pricingSummary?.mixedResult.missingKeys ?? [];
      if (missing.isNotEmpty) {
        debugPrint('[BasketPricing] missing items: ${missing.join(', ')}');
      }

      if (pricingSummary?.bestSingleMarket == null) {
        final reasons = pricingSummary?.perMarketTotals.entries
                .map((entry) =>
                    '${entry.key}: missing=${entry.value.missingKeys.join(', ')}')
                .join(' | ') ??
            '-';
        debugPrint('[BasketPricing] best single market yok. Eksikler: $reasons');
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

  String _itemKey(BasketItemModel item, ProductModel? product) {
    if (item.productId.trim().isNotEmpty) {
      return item.productId.trim();
    }
    final barcode = product?.barcode?.trim();
    if (barcode != null && barcode.isNotEmpty) {
      return barcode;
    }
    final name = product?.name.trim();
    if (name != null && name.isNotEmpty) {
      return _normalizeName(name);
    }
    return item.productId;
  }

  String _normalizeName(String value) {
    final trimmed = value.trim().toLowerCase();
    final replaced = trimmed
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
        .replaceAll('Ç', 'c');
    return replaced.replaceAll(RegExp(r'\s+'), ' ');
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
  );

  ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
    viewModel.setUser(next.value?.uid);
  });

  viewModel.setUser(ref.read(authStateProvider).value?.uid);
  return viewModel;
});
