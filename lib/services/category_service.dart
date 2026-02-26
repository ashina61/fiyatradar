import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/category_model.dart';

class CategoryService {
  CategoryService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  Stream<List<CategoryModel>> getCategories() {
    return _categoriesRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map(CategoryModel.fromFirestore)
          .where((category) => category.isActive)
          .toList();
      list.sort((a, b) {
        final aOrder = a.order;
        final bOrder = b.order;
        if (aOrder != null && bOrder != null) {
          return aOrder.compareTo(bOrder);
        }
        if (aOrder != null) return -1;
        if (bOrder != null) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return list;
    });
  }

  Future<String> addCategory(
    String title,
    String iconName, {
    String? imageUrl,
    String? imagePath,
    bool isActive = true,
    int? order,
  }) async {
    final normalizedId = title
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final doc = await _categoriesRef.add({
      'id': normalizedId,
      'title': title,
      'iconName': iconName.trim().isEmpty ? 'category' : iconName.trim(),
      'isActive': isActive,
      if (order != null) 'sort': order,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
      if (imagePath != null && imagePath.isNotEmpty) 'imagePath': imagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> updateCategory(String categoryId, Map<String, dynamic> data) async {
    final sanitized = Map<String, dynamic>.from(data)
      ..remove('name')
      ..remove('order');
    if (sanitized.containsKey('title') && sanitized['title'] is String) {
      final title = (sanitized['title'] as String).trim();
      sanitized['title'] = title;
      sanitized['id'] = title
          .toLowerCase()
          .replaceAll('ı', 'i')
          .replaceAll('ğ', 'g')
          .replaceAll('ü', 'u')
          .replaceAll('ş', 's')
          .replaceAll('ö', 'o')
          .replaceAll('ç', 'c')
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'^_+|_+$'), '');
    }
    if (sanitized.containsKey('sort') && sanitized['sort'] is! num) {
      sanitized.remove('sort');
    }
    if (sanitized.containsKey('iconName')) {
      final value = (sanitized['iconName'] ?? '').toString().trim();
      sanitized['iconName'] = value.isEmpty ? 'category' : value;
    }
    await _categoriesRef.doc(categoryId).update({
      ...sanitized,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categoriesRef.doc(categoryId).delete();
  }
}
