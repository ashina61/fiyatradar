import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../models/actual_item_model.dart';
import '../models/actual_model.dart';
import 'product_provider.dart';

final actualAdminFilterProvider = StateProvider<bool?>((ref) => null);

final adminActualsProvider = StreamProvider<List<ActualModel>>((ref) {
  if (!firebaseInitialized) return Stream.value([]);
  final filter = ref.watch(actualAdminFilterProvider);
  return ref.watch(firestoreServiceProvider).getActualsForAdmin(isActive: filter);
});

final latestActiveActualProvider = StreamProvider<ActualModel?>((ref) {
  if (!firebaseInitialized) return Stream.value(null);
  return ref.watch(firestoreServiceProvider).getLatestActiveActualForUser();
});

final actualItemsProvider = StreamProvider.family<List<ActualItemModel>, String>((ref, actualId) {
  if (!firebaseInitialized || actualId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActualItems(actualId);
});

final adminActualItemsProvider = StreamProvider.family<List<ActualItemModel>, String>((ref, actualId) {
  if (!firebaseInitialized || actualId.isEmpty) return Stream.value([]);
  return ref.watch(firestoreServiceProvider).getActualItems(actualId);
});
