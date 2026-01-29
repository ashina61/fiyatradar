import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllUsers();
});

final savedProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  final userModel = ref.watch(userModelStreamProvider);
  return userModel.when(
    data: (user) {
      if (user != null && user.savedProducts.isNotEmpty) {
        return ref
            .watch(firestoreServiceProvider)
            .getSavedProducts(user.savedProducts);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

final searchHistoryProvider = StreamProvider<List<String>>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.watch(firestoreServiceProvider).getSearchHistory(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

class UserNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final AuthService _authService;

  UserNotifier(this._firestoreService, this._authService)
      : super(const AsyncValue.data(null));

  Future<void> toggleSavedProduct(String productId) async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _authService.toggleSavedProduct(currentUser.uid, productId);
    }
  }

  Future<void> saveSearch(String query) async {
    final currentUser = _authService.currentUser;
    if (currentUser != null && query.isNotEmpty) {
      await _firestoreService.saveSearchHistory(currentUser.uid, query);
    }
  }

  Future<void> clearSearchHistory() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      await _firestoreService.clearSearchHistory(currentUser.uid);
    }
  }

  Future<void> toggleUserAdmin(String userId, bool isAdmin) async {
    await _firestoreService.updateUserAdmin(userId, isAdmin);
  }
}

final userNotifierProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<void>>((ref) {
  return UserNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// Is product saved by current user
final isProductSavedProvider =
    Provider.family<bool, String>((ref, productId) {
  final userModel = ref.watch(userModelStreamProvider);
  return userModel.when(
    data: (user) => user?.savedProducts.contains(productId) ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});
