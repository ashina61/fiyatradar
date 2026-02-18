import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_init_provider.dart';
import '../models/actual_item_model.dart';
import '../models/actual_model.dart';
import 'product_provider.dart';

final actualAdminFilterProvider = StateProvider<bool?>((ref) => null);

final adminActualsProvider = StreamProvider<List<ActualModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value([]);
  final filter = ref.watch(actualAdminFilterProvider);
  return ref.watch(firestoreServiceProvider).getActualsForAdmin(isActive: filter);
});

final latestActiveActualProvider = StreamProvider<ActualModel?>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getLatestActiveActualForUser();
});

final actualItemsProvider = StreamProvider.family<List<ActualItemModel>, String>((ref, actualId) {
  if (!ref.watch(firebaseInitializedProvider) || actualId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActualItems(actualId);
});

final adminActualItemsProvider = StreamProvider.family<List<ActualItemModel>, String>((ref, actualId) {
  if (!ref.watch(firebaseInitializedProvider) || actualId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActualItems(actualId);
});
