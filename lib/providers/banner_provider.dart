import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/banner_model.dart';
import '../services/banner_service.dart';

final bannerServiceProvider = Provider<BannerService>((ref) {
  return BannerService();
});

final bannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerServiceProvider).getActiveBanners();
});

final activeBannersProvider = bannersProvider;

final allBannersProvider = StreamProvider<List<BannerModel>>((ref) {
  return ref.watch(bannerServiceProvider).getAllBanners();
});

final bannerNotifierProvider = NotifierProvider<BannerNotifier, void>(BannerNotifier.new);

class BannerNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> deleteBanner(String bannerId) async {
    await ref.read(bannerServiceProvider).deleteBanner(bannerId);
    _refresh();
  }

  Future<void> toggleBannerActive(String bannerId, bool isActive) async {
    await ref.read(bannerServiceProvider).updateBanner(bannerId, {'isActive': isActive});
    _refresh();
  }

  Future<void> addBanner(BannerModel banner) async {
    await ref.read(bannerServiceProvider).addBanner(banner);
    _refresh();
  }

  Future<void> updateBanner(String bannerId, Map<String, dynamic> data) async {
    await ref.read(bannerServiceProvider).updateBanner(bannerId, data);
    _refresh();
  }

  void _refresh() {
    ref.invalidate(bannersProvider);
    ref.invalidate(allBannersProvider);
  }
}
