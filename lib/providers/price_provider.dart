import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_init_provider.dart';
import '../models/price_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'auth_provider.dart';
import 'product_provider.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final pricesForProductProvider =
    StreamProvider.family<List<PriceModel>, String>((ref, productId) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getPricesForProduct(productId);
});

final latestPriceProvider =
    FutureProvider.family<PriceModel?, String>((ref, productId) async {
  if (!ref.watch(firebaseInitializedProvider)) return null;
  return ref.watch(firestoreServiceProvider).getLatestPrice(productId);
});

final pendingPricesProvider = StreamProvider<List<PriceModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getPendingPrices();
});

class PriceNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;
  final LocationService _locationService;
  final AuthService _authService;

  PriceNotifier(
    this._firestoreService,
    this._storageService,
    this._locationService,
    this._authService,
  ) : super(const AsyncValue.data(null));

  Future<void> addPrice({
    required String productId,
    required double price,
    required String branchStoreId,
    String? chainId,
    required String storeName,
    List<File>? images,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('Kullanici oturumu bulunamadi');
      }

      final userModel = await _authService.getUserModel(currentUser.uid);
      final locationData = await _locationService.getLocationData();

      // Create price ID first
      final priceId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload images if any
      List<String> imageUrls = [];
      if (images != null && images.isNotEmpty) {
        imageUrls = await _storageService.uploadPriceImages(
          files: images,
          priceId: priceId,
        );
      }

      final priceModel = PriceModel(
        id: priceId,
        productId: productId,
        userId: currentUser.uid,
        userName: userModel?.name,
        price: price,
        branchStoreId: branchStoreId,
        chainId: chainId,
        storeName: storeName,
        storeLocation: locationData?.address,
        geoPoint: locationData?.geoPoint,
        images: imageUrls,
        reportedAt: DateTime.now(),
        isPending: true,
        addedByTrustScoreSnapshot: userModel?.reliabilityScore ?? 0,
        addedByLevelSnapshot: ((userModel?.points ?? 0) >= 5000) ? 'Elmas' : (((userModel?.points ?? 0) >= 2000) ? 'Gümüş' : (((userModel?.points ?? 0) >= 500) ? 'Bronz' : 'Standart')),
        addedByVerifiedBadge: (userModel?.points ?? 0) >= 5000,
        createdByTrustScoreSnapshot: userModel?.reliabilityScore ?? 0,
        createdByBadgeSnapshot: ((userModel?.points ?? 0) >= 5000) ? 'Elmas' : (((userModel?.points ?? 0) >= 2000) ? 'Gümüş' : (((userModel?.points ?? 0) >= 500) ? 'Bronz' : 'Standart')),
        createdByVerifiedSnapshot: (userModel?.points ?? 0) >= 5000,
      );

      await _firestoreService.addPriceReport(priceModel);

      // Update user stats
      await _authService.incrementPriceEntries(currentUser.uid);

      // Add points (2x for photos)
      final points = images != null && images.isNotEmpty
          ? AppConstants.pointsForPriceEntryWithPhoto
          : AppConstants.pointsForPriceEntry;
      await _authService.addPoints(currentUser.uid, points);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyPrice(String priceId, bool isVerified) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await _firestoreService.verifyPrice(priceId, currentUser.uid, isVerified);
  }

  Future<void> approvePrice(String priceId) async {
    await _firestoreService.approvePrice(priceId);
  }

  Future<void> rejectPrice(String priceId) async {
    await _firestoreService.rejectPrice(priceId);
  }
}

final priceNotifierProvider =
    StateNotifierProvider<PriceNotifier, AsyncValue<void>>((ref) {
  return PriceNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
    ref.watch(locationServiceProvider),
    ref.watch(authServiceProvider),
  );
});

// Location state
final currentLocationProvider = FutureProvider<LocationData?>((ref) async {
  return ref.watch(locationServiceProvider).getLocationData();
});
