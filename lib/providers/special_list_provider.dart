import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/special_list_item_model.dart';
import '../models/special_list_model.dart';
import '../services/special_list_service.dart';
import 'firebase_init_provider.dart';

final specialListServiceProvider = Provider<SpecialListService>((ref) {
  return SpecialListService();
});

final adminSpecialListsProvider = StreamProvider<List<SpecialListModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(specialListServiceProvider).watchSpecialLists();
});

final activeSpecialListsProvider = StreamProvider<List<SpecialListModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(specialListServiceProvider).watchSpecialLists(activeOnly: true);
});

final specialListByIdProvider = StreamProvider.family<SpecialListModel?, String>((ref, listId) {
  if (!ref.watch(firebaseInitializedProvider) || listId.trim().isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(specialListServiceProvider).watchSpecialList(listId);
});

final specialListItemsProvider = StreamProvider.family<List<SpecialListItemModel>, String>((ref, listId) {
  if (!ref.watch(firebaseInitializedProvider) || listId.trim().isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(specialListServiceProvider).watchItems(listId, activeOnly: true);
});

class SpecialListDetailState {
  const SpecialListDetailState({
    required this.list,
    required this.items,
  });

  final AsyncValue<SpecialListModel?> list;
  final AsyncValue<List<SpecialListItemModel>> items;
}

final specialListDetailProvider = Provider.family<SpecialListDetailState, String>((ref, listId) {
  return SpecialListDetailState(
    list: ref.watch(specialListByIdProvider(listId)),
    items: ref.watch(specialListItemsProvider(listId)),
  );
});
