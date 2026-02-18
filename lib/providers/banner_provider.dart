import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_init_provider.dart';
import '../models/banner_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'product_provider.dart';
import 'price_provider.dart';

final activeBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActiveBanners();
});

final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getAllBanners();
});

class BannerNotifier extends StateNotifier<AsyncValue<void>> {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  BannerNotifier(this._firestoreService, this._storageService)
      : super(const AsyncValue.data(null));

  Future<void> addBanner({
    required String title,
    String? description,
    required File imageFile,
    String? actionUrl,
    String? productId,
    int order = 0,
    DateTime? expiresAt,
  }) async {
    state = const AsyncValue.loading();
    try {
      final bannerId = DateTime.now().millisecondsSinceEpoch.toString();
      final imageUrl = await _storageService.uploadBannerImage(
        file: imageFile,
        bannerId: bannerId,
      );

      final banner = BannerModel(
        id: bannerId,
        title: title,
        description: description,
        imageUrl: imageUrl,
        actionUrl: actionUrl,
        productId: productId,
        order: order,
        createdAt: DateTime.now(),
        expiresAt: expiresAt,
      );

      await _firestoreService.addBanner(banner);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    await _firestoreService.updateBanner(bannerId, data);
  }

  Future<void> toggleBannerActive(String bannerId, bool isActive) async {
    await _firestoreService.updateBanner(bannerId, {'isActive': isActive});
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestoreService.deleteBanner(bannerId);
  }
}

final bannerNotifierProvider =
    StateNotifierProvider<BannerNotifier, AsyncValue<void>>((ref) {
  return BannerNotifier(
    ref.watch(firestoreServiceProvider),
    ref.watch(storageServiceProvider),
  );
});
