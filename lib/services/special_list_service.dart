import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/special_list_item_model.dart';
import '../models/special_list_model.dart';

class SpecialListService {
  SpecialListService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _specialLists => _firestore.collection('special_lists');

  Stream<List<SpecialListModel>> streamSpecialLists({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _specialLists.orderBy('sortOrder').orderBy('createdAt', descending: true);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map(SpecialListModel.fromFirestore).toList());
  }

  Stream<SpecialListModel?> streamSpecialList(String listId) {
    return _specialLists.doc(listId).snapshots().map((doc) => doc.exists ? SpecialListModel.fromFirestore(doc) : null);
  }

  Stream<List<SpecialListItemModel>> streamSpecialListItems(String listId, {bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _specialLists.doc(listId).collection('items').orderBy('sortOrder');
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) => snapshot.docs.map(SpecialListItemModel.fromFirestore).toList());
  }

  Future<String> createSpecialList({
    required String title,
    required String subtitle,
    required String badgeText,
    required String description,
    required String coverType,
    String? coverImageUrl,
    required double totalPrice,
    required double savingsAmount,
    required String savingsLabel,
    required String bestMarketName,
    required String ctaText,
    required SpecialListCtaActionType ctaActionType,
    required bool isActive,
    required int sortOrder,
  }) async {
    final doc = _specialLists.doc();
    final now = FieldValue.serverTimestamp();
    await doc.set({
      'id': doc.id,
      'title': title,
      'subtitle': subtitle,
      'badgeText': badgeText,
      'description': description,
      'coverType': coverType,
      'coverImageUrl': coverImageUrl,
      'totalPrice': totalPrice,
      'savingsAmount': savingsAmount,
      'savingsLabel': savingsLabel,
      'bestMarketName': bestMarketName,
      'ctaText': ctaText,
      'ctaActionType': ctaActionType.value,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': now,
      'updatedAt': now,
    });
    return doc.id;
  }

  Future<void> updateSpecialList(String listId, Map<String, dynamic> data) {
    return _specialLists.doc(listId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  Future<void> deleteSpecialList(String listId) async {
    final items = await _specialLists.doc(listId).collection('items').get();
    final batch = _firestore.batch();
    for (final doc in items.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_specialLists.doc(listId));
    await batch.commit();
  }

  Future<void> upsertSpecialListItem({
    required String listId,
    String? itemId,
    required SpecialListItemModel item,
  }) async {
    final ref = itemId == null
        ? _specialLists.doc(listId).collection('items').doc()
        : _specialLists.doc(listId).collection('items').doc(itemId);
    await ref.set(item.copyWith(id: ref.id).toFirestore(), SetOptions(merge: true));
  }

  Future<void> deleteSpecialListItem({required String listId, required String itemId}) {
    return _specialLists.doc(listId).collection('items').doc(itemId).delete();
  }
}
