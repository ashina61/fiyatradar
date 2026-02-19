import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_init_provider.dart';
import '../models/product_model.dart';
import '../models/comment_model.dart';
import '../models/price_model.dart';
import '../models/brand_model.dart';
import '../models/store_model.dart';
import '../models/store_suggestion_model.dart';
import '../models/category_model.dart';
import '../models/category_theme.dart';
import '../models/product_suggestion_model.dart';
import '../services/catalog_service.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService();
});

final trendingProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getTrendingProducts();
});

final recommendedProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getRecommendedProducts();
});

final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getAllProducts();
});

final productProvider = FutureProvider.family<ProductModel?, String>((ref, productId) async {
  if (!ref.watch(firebaseInitializedProvider)) return null;
  return ref.watch(catalogServiceProvider).getProduct(productId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

// Category filter for search screen (set from home screen category tap)
final selectedCategoryFilterProvider = StateProvider<String>((ref) => 'Tumu');
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || !ref.watch(firebaseInitializedProvider)) {
    return [];
  }
  return ref.watch(catalogServiceProvider).searchProducts(query);
});

class ProductNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;

  ProductNotifier(this._firestoreService) : super(const AsyncValue.data(null));

  Future<String> addProduct(ProductModel product) async {
    state = const AsyncValue.loading();
    try {
      final id = await _firestoreService.addProduct(product);
      state = const AsyncValue.data(null);
      return id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> incrementViewCount(String productId) async {
    await _firestoreService.incrementViewCount(productId);
  }
}

final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, AsyncValue<void>>((ref) {
  return ProductNotifier(ref.watch(firestoreServiceProvider));
});


final orderedCategoriesProvider = Provider<List<CategoryModel>>((ref) {
  final categories = ref.watch(categoriesProvider).valueOrNull ?? const <CategoryModel>[];

  final uniqueByCanonical = <String, CategoryModel>{};
  for (final category in categories) {
    uniqueByCanonical.putIfAbsent(category.canonicalId, () => category);
  }

  final ordered = uniqueByCanonical.values.toList()
    ..sort((a, b) {
      final aTheme = CategoryThemeCatalog.resolve(id: a.canonicalId, title: a.title);
      final bTheme = CategoryThemeCatalog.resolve(id: b.canonicalId, title: b.title);
      final byThemeOrder = aTheme.sortOrder.compareTo(bTheme.sortOrder);
      if (byThemeOrder != 0) return byThemeOrder;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

  return ordered;
});

// Categories
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getCategories();
});

/// @deprecated Use [allStoresStreamProvider] or [activeStoresProvider] instead.
final storesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getStores();
});

// Product by ID (stream version)
final productByIdProvider = StreamProvider.family<ProductModel?, String>((ref, productId) {
  if (!ref.watch(firebaseInitializedProvider) || productId.isEmpty) return Stream.value(null);
  return ref.watch(catalogServiceProvider).getProductStream(productId);
});

// Comments for a product
final productCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, productId) {
  if (!ref.watch(firebaseInitializedProvider) || productId.isEmpty) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getComments(productId);
});

// Price history for a product
final productPriceHistoryProvider = StreamProvider.family<List<PriceModel>, String>((ref, productId) {
  if (!ref.watch(firebaseInitializedProvider) || productId.isEmpty) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getPricesForProduct(productId);
});

// Latest prices across all products (for home screen)
final latestPricesProvider = StreamProvider<List<PriceModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getLatestPrices(limit: 10);
});

// Reports (for admin panel)
final reportsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getReports();
});

// Maintenance mode
final maintenanceModeProvider = StreamProvider<bool>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(false);
  return ref.watch(firestoreServiceProvider).getMaintenanceMode();
});

// =========================================================================
// BRANDS
// =========================================================================

final allBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllBrands();
});

final activeBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActiveBrands();
});

// =========================================================================
// STORES (Subeler)
// =========================================================================

final allStoresStreamProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllStoresStream();
});

final activeStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActiveStores();
});


final nearbyStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getNearbyActiveStoresStream();
});

final onlineStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getOnlineActiveStoresStream();
});

final pendingStoreSuggestionsProvider =
    StreamProvider<List<StoreSuggestionModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getPendingStoreSuggestions();
});


final pendingProductSuggestionsProvider =
    StreamProvider<List<ProductSuggestionModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getPendingProductSuggestions();
});


final weeklyDealsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getWeeklyDeals();
});

final dealItemsProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, dealId) {
  if (!ref.watch(firebaseInitializedProvider) || dealId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getDealItems(dealId);
});


final favoriteOverrideProvider = StateProvider.family<bool?, String>((ref, productId) => null);

final isFavoriteProvider = StreamProvider.family<bool, String>((ref, productId) {
  if (!ref.watch(firebaseInitializedProvider) || productId.trim().isEmpty) return Stream.value(false);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(false);
  return ref.watch(firestoreServiceProvider).isFavoriteStream(uid: user.uid, productId: productId);
});

final recentlyViewedProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).recentlyViewedStream(user.uid);
});


