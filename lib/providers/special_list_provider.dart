import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/special_list_item_model.dart';
import '../models/special_list_model.dart';
import '../services/special_list_service.dart';
import 'firebase_init_provider.dart';

final specialListServiceProvider = Provider<SpecialListService>((ref) {
  return SpecialListService();
});

final specialListsProvider = StreamProvider<List<SpecialListModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(specialListServiceProvider).streamSpecialLists(activeOnly: true);
});

final adminSpecialListsProvider = StreamProvider<List<SpecialListModel>>((ref) {
  if (!ref.watch(firebaseInitializedProvider)) return Stream.value(const []);
  return ref.watch(specialListServiceProvider).streamSpecialLists(activeOnly: false);
});

final specialListByIdProvider = StreamProvider.family<SpecialListModel?, String>((ref, listId) {
  if (!ref.watch(firebaseInitializedProvider) || listId.isEmpty) {
    return Stream.value(null);
  }
  return ref.watch(specialListServiceProvider).streamSpecialList(listId);
});

final specialListItemsProvider = StreamProvider.family<List<SpecialListItemModel>, String>((ref, listId) {
  if (!ref.watch(firebaseInitializedProvider) || listId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(specialListServiceProvider).streamSpecialListItems(listId, activeOnly: true);
});

final adminSpecialListItemsProvider = StreamProvider.family<List<SpecialListItemModel>, String>((ref, listId) {
  if (!ref.watch(firebaseInitializedProvider) || listId.isEmpty) {
    return Stream.value(const []);
  }
  return ref.watch(specialListServiceProvider).streamSpecialListItems(listId, activeOnly: false);
});

class SpecialListDetailState {
  const SpecialListDetailState({required this.list, required this.items});

  final AsyncValue<SpecialListModel?> list;
  final AsyncValue<List<SpecialListItemModel>> items;

  bool get isLoading => list.isLoading || items.isLoading;

  Object? get error => list.asError?.error ?? items.asError?.error;
}

final specialListDetailProvider = Provider.family<SpecialListDetailState, String>((ref, listId) {
  return SpecialListDetailState(
    list: ref.watch(specialListByIdProvider(listId)),
    items: ref.watch(specialListItemsProvider(listId)),
  );
});
