import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'service_providers.dart';
import '../services/domain_services.dart';
import 'auth_provider.dart';

export 'service_providers.dart' show firestoreServiceProvider;

const int _adminProductPageSize = 60;

final catalogServiceProvider = Provider<CatalogService>((ref) {
  return CatalogService();
});


final brandDomainServiceProvider = Provider<BrandDomainService>((ref) {
  return BrandDomainService(ref.watch(firestoreServiceProvider));
});

final storeDomainServiceProvider = Provider<StoreDomainService>((ref) {
  return StoreDomainService(ref.watch(firestoreServiceProvider));
});

final adminModerationDomainServiceProvider =
    Provider<AdminModerationDomainService>((ref) {
  return AdminModerationDomainService(ref.watch(firestoreServiceProvider));
});

final productSuggestionDomainServiceProvider =
    Provider<ProductSuggestionDomainService>((ref) {
  return ProductSuggestionDomainService(ref.watch(firestoreServiceProvider));
});

final adminUserManagementDomainServiceProvider =
    Provider<AdminUserManagementDomainService>((ref) {
  return AdminUserManagementDomainService(ref.watch(firestoreServiceProvider));
});

final adminBrandManagementDomainServiceProvider =
    Provider<AdminBrandManagementDomainService>((ref) {
  return AdminBrandManagementDomainService(ref.watch(firestoreServiceProvider));
});

final actualAdminDomainServiceProvider =
    Provider<ActualAdminDomainService>((ref) {
  return ActualAdminDomainService(ref.watch(firestoreServiceProvider));
});

final adminCategoryManagementDomainServiceProvider =
    Provider<AdminCategoryManagementDomainService>((ref) {
  return AdminCategoryManagementDomainService(ref.watch(firestoreServiceProvider));
});

final adminBannerManagementDomainServiceProvider =
    Provider<AdminBannerManagementDomainService>((ref) {
  return AdminBannerManagementDomainService(ref.watch(firestoreServiceProvider));
});

final adminCampaignManagementDomainServiceProvider =
    Provider<AdminCampaignManagementDomainService>((ref) {
  return AdminCampaignManagementDomainService(ref.watch(firestoreServiceProvider));
});

final trendingProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getTrendingProducts();
});

final recommendedProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getRecommendedProducts();
});

final editorPickProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getEditorPickProducts(limit: 3);
});

final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(catalogServiceProvider).getAllProducts();
});

final adminScopedProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAdminProductsScoped(limit: 300);
});

class AdminCatalogProductsState {
  const AdminCatalogProductsState({
    this.products = const <ProductModel>[],
    this.isInitialLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
  });

  final List<ProductModel> products;
  final bool isInitialLoading;
  final bool isLoadingMore;
  final bool hasMore;

  AdminCatalogProductsState copyWith({
    List<ProductModel>? products,
    bool? isInitialLoading,
    bool? isLoadingMore,
    bool? hasMore,
  }) {
    return AdminCatalogProductsState(
      products: products ?? this.products,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class AdminCatalogProductsNotifier
    extends StateNotifier<AsyncValue<AdminCatalogProductsState>> {
  AdminCatalogProductsNotifier(this._firestoreService)
      : super(const AsyncValue.data(AdminCatalogProductsState()));

  final FirestoreService _firestoreService;
  QueryDocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _initialized = false;

  Future<void> loadInitial() async {
    if (_initialized) return;
    _initialized = true;
    state = const AsyncValue.data(
      AdminCatalogProductsState(isInitialLoading: true, hasMore: true),
    );
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isInitialLoading || current.isLoadingMore || !current.hasMore) {
      return;
    }
    state = AsyncValue.data(current.copyWith(isLoadingMore: true));
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    try {
      final currentProducts = reset
          ? const <ProductModel>[]
          : (state.valueOrNull?.products ?? const <ProductModel>[]);
      final page = await _firestoreService.getAdminProductsPage(
        pageSize: _adminProductPageSize,
        startAfter: reset ? null : _lastDoc,
      );
      _lastDoc = page.lastDocument;
      state = AsyncValue.data(
        AdminCatalogProductsState(
          products: [...currentProducts, ...page.products],
          isInitialLoading: false,
          isLoadingMore: false,
          hasMore: page.hasMore,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final adminCatalogProductsProvider = StateNotifierProvider<
    AdminCatalogProductsNotifier, AsyncValue<AdminCatalogProductsState>>((ref) {
  final notifier = AdminCatalogProductsNotifier(ref.watch(firestoreServiceProvider));
  notifier.loadInitial();
  return notifier;
});

final adminProductTypeaheadProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, query) async {
  if (!ref.watch(firebaseInitializedProvider)) return const [];
  final normalized = query.trim();
  if (normalized.length < 2) return const [];
  return ref.watch(firestoreServiceProvider).searchProductsByPrefix(
        normalized,
        limit: 20,
      );
});

final productProvider = FutureProvider.family<ProductModel?, String>((ref, productId) async {
  if (!ref.watch(firebaseInitializedProvider)) return null;
  return ref.watch(catalogServiceProvider).getProduct(productId);
});

final dailyDealProductProvider = StreamProvider<ProductModel?>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getDailyDealProduct();
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
  return ref.watch(adminModerationDomainServiceProvider).getReports();
});

// Maintenance mode
final maintenanceModeProvider = StreamProvider<bool>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(false);
  return ref.watch(adminModerationDomainServiceProvider).getMaintenanceMode();
});

// =========================================================================
// BRANDS
// =========================================================================

final allBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(brandDomainServiceProvider).getAllBrands();
});

final activeBrandsProvider = StreamProvider<List<BrandModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(brandDomainServiceProvider).getActiveBrands();
});

// =========================================================================
// STORES (Şubeler)
// =========================================================================

final allStoresStreamProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(storeDomainServiceProvider).getAllStoresStream();
});

final adminScopedStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAdminStoresScoped(limit: 200);
});

final adminStoreTypeaheadProvider =
    FutureProvider.family<List<StoreModel>, String>((ref, query) async {
  if (!ref.watch(firebaseInitializedProvider)) return const [];
  return ref.watch(firestoreServiceProvider).searchAdminStoresByPrefix(
        query,
        limit: 20,
      );
});

final activeStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(storeDomainServiceProvider).getActiveStores();
});


final nearbyStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(storeDomainServiceProvider).getNearbyActiveStoresStream();
});

final onlineStoresProvider = StreamProvider<List<StoreModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(storeDomainServiceProvider).getOnlineActiveStoresStream();
});

final pendingStoreSuggestionsProvider =
    StreamProvider<List<StoreSuggestionModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getPendingStoreSuggestions();
});


final pendingProductSuggestionsProvider =
    StreamProvider<List<ProductSuggestionModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(productSuggestionDomainServiceProvider).getPendingProductSuggestions();
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
