import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/special_list_item_model.dart';
import '../models/special_list_model.dart';

class SpecialListService {
  SpecialListService({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listsRef => _firestore.collection('special_lists');

  CollectionReference<Map<String, dynamic>> _itemsRef(String listId) => _listsRef.doc(listId).collection('items');

  Stream<List<SpecialListModel>> watchSpecialLists({bool activeOnly = false}) {
    Query<Map<String, dynamic>> query = _listsRef;
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final lists = snapshot.docs.map(SpecialListModel.fromFirestore).toList()
        ..sort((a, b) {
          final orderCompare = a.sortOrder.compareTo(b.sortOrder);
          if (orderCompare != 0) return orderCompare;
          return b.createdAt.compareTo(a.createdAt);
        });
      return lists;
    });
  }

  Stream<SpecialListModel?> watchSpecialList(String listId) {
    return _listsRef.doc(listId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return SpecialListModel.fromFirestore(doc);
    });
  }

  Stream<List<SpecialListItemModel>> watchItems(String listId, {bool activeOnly = true}) {
    Query<Map<String, dynamic>> query = _itemsRef(listId);
    if (activeOnly) {
      query = query.where('isActive', isEqualTo: true);
    }
    return query.snapshots().map((snapshot) {
      final items = snapshot.docs.map(SpecialListItemModel.fromFirestore).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return items;
    });
  }

  Future<String> createSpecialList(Map<String, dynamic> payload) async {
    final doc = _listsRef.doc();
    await doc.set({
      ...payload,
      'id': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateSpecialList(String listId, Map<String, dynamic> payload) {
    return _listsRef.doc(listId).update({
      ...payload,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteSpecialList(String listId) async {
    final items = await _itemsRef(listId).get();
    final batch = _firestore.batch();
    for (final itemDoc in items.docs) {
      batch.delete(itemDoc.reference);
    }
    batch.delete(_listsRef.doc(listId));
    await batch.commit();
  }

  Future<void> addItem(String listId, SpecialListItemModel item) async {
    final doc = _itemsRef(listId).doc();
    await doc.set(item.toFirestore());
  }

  Future<void> updateItem(String listId, String itemId, Map<String, dynamic> payload) {
    return _itemsRef(listId).doc(itemId).update(payload);
  }

  Future<void> deleteItem(String listId, String itemId) {
    return _itemsRef(listId).doc(itemId).delete();
  }
}
