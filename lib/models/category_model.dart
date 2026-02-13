import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;
  final bool isActive;
  final int? order;
  final Timestamp? updatedAt;
  final String iconName;
  final String? imagePath;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.isActive,
    this.order,
    this.updatedAt,
    this.iconName = 'category',
    this.imagePath,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return CategoryModel(
      id: doc.id,
      name: (data['name'] ?? '').toString(),
      imageUrl: data['imageUrl']?.toString(),
      isActive: data['isActive'] != false,
      order: data['order'] is num ? (data['order'] as num).toInt() : null,
      updatedAt: data['updatedAt'] as Timestamp?,
      iconName: (data['iconName'] ?? 'category').toString(),
      imagePath: data['imagePath']?.toString(),
    );
  }

  String? get versionedImageUrl {
    final base = imageUrl;
    if (base == null || base.isEmpty) return null;
    final version = updatedAt?.millisecondsSinceEpoch;
    if (version == null) return base;
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}v=$version';
  }
}
