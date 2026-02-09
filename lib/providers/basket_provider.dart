import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/basket_item_model.dart';
import '../models/product_model.dart';
import '../services/basket_pricing_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final basketPricingServiceProvider = Provider<BasketPricingService>((ref) {
  return BasketPricingService(ref.watch(firestoreServiceProvider));
});

final basketItemsProvider = StreamProvider<List<BasketItemModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value([]);
      return ref
          .watch(firestoreServiceProvider)
          .getBasketItems(user.uid)
          .map((items) => items.map(BasketItemModel.fromFirestore).toList());
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final basketProductsProvider = FutureProvider<Map<String, ProductModel>>((ref) async {
  final items = ref.watch(basketItemsProvider).valueOrNull ?? [];
  final ids = items.map((e) => e.productId).toList();
  if (ids.isEmpty) return {};
  final allProducts = await ref.watch(allProductsProvider.future);
  final Map<String, ProductModel> map = {
    for (final product in allProducts) product.id: product,
  };
  return {
    for (final id in ids)
      if (map.containsKey(id)) id: map[id]!,
  };
});

final basketCalculationProvider = FutureProvider<BasketPricingResult>((ref) async {
  final items = ref.watch(basketItemsProvider).valueOrNull ?? [];
  if (items.isEmpty) {
    return BasketPricingResult(
      bestSingleMarket: null,
      mixedBasket: MixedBasketResult(
        total: 0,
        perItemCheapest: {},
        missingProductIds: const [],
      ),
      perMarketTotals: {},
      perMarketMissingCount: {},
      marketNames: {},
    );
  }
  final productMap = await ref.watch(basketProductsProvider.future);
  return ref.watch(basketPricingServiceProvider).calculateRecommendations(items, productMap);
});
