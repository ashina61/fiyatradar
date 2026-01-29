import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final trendingProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getTrendingProducts();
});

final recommendedProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getRecommendedProducts();
});

final allProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllProducts();
});

final productProvider = FutureProvider.family<ProductModel?, String>((ref, productId) async {
  if (!firebaseInitialized) return null;
  return ref.watch(firestoreServiceProvider).getProduct(productId);
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty || !firebaseInitialized) {
    return [];
  }
  return ref.watch(firestoreServiceProvider).searchProducts(query);
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
