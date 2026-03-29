import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_init_provider.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'auth_provider.dart';
import 'service_providers.dart';

final adminScopedUsersProvider = StreamProvider<List<UserModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).watchAdminUsersScoped(limit: 200);
});

class AdminUserStatsSummary {
  const AdminUserStatsSummary({
    required this.userCount,
    required this.totalPriceEntries,
    required this.totalPoints,
  });

  final int userCount;
  final int totalPriceEntries;
  final int totalPoints;
}

final adminUserStatsProvider = FutureProvider<AdminUserStatsSummary>((ref) async {
  if (!ref.watch(firebaseInitializedProvider)) {
    return const AdminUserStatsSummary(
      userCount: 0,
      totalPriceEntries: 0,
      totalPoints: 0,
    );
  }

  final stats = await ref.watch(firestoreServiceProvider).getAdminUserStatsSnapshot();

  return AdminUserStatsSummary(
    userCount: stats.userCount,
    totalPriceEntries: stats.totalPriceEntries,
    totalPoints: stats.totalPoints,
  );
});

final homeTopUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  if (!ref.watch(firebaseInitializedProvider)) return const [];
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .orderBy('totalPoints', descending: true)
      .limit(20)
      .get();
  final users = snapshot.docs.map(UserModel.fromFirestore).toList(growable: false);
  users.sort((a, b) {
    final byPoints = b.points.compareTo(a.points);
    if (byPoints != 0) return byPoints;
    final byTrust = b.trustScorePercent.compareTo(a.trustScorePercent);
    if (byTrust != 0) return byTrust;
    return b.priceEntries.compareTo(a.priceEntries);
  });
  return users.take(2).toList(growable: false);
});

final todaysNewUsersCountProvider = FutureProvider<int>((ref) async {
  if (!ref.watch(firebaseInitializedProvider)) return 0;
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  final query = FirebaseFirestore.instance
      .collection('users')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
      .where('createdAt', isLessThan: Timestamp.fromDate(end));
  final count = await query.count().get();
  return count.count;
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
