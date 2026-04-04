import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_init_provider.dart';
import '../models/campaign_basket_model.dart';
import '../models/product_model.dart';
import 'product_provider.dart';

final allCampaignsProvider = StreamProvider<List<CampaignBasketModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).getAllCampaigns();
});

final activeCampaignsProvider = StreamProvider<List<CampaignBasketModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).getActiveCampaigns();
});

final campaignByIdProvider = FutureProvider.family<CampaignBasketModel?, String>((ref, id) async {
  if (!ref.watch(firebaseInitializedProvider) || id.trim().isEmpty) return null;
  return ref.watch(firestoreServiceProvider).getCampaignById(id);
});

final campaignProductsProvider = StreamProvider.family<List<ProductModel>, List<String>>((ref, ids) {
  if (!ref.watch(firebaseInitializedProvider) || ids.isEmpty) return Stream.value(const []);
  return ref.watch(firestoreServiceProvider).getSavedProducts(ids);
});
