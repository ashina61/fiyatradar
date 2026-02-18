import 'package:cloud_firestore/cloud_firestore.dart';

import 'category_theme.dart';

class CategoryModel {
  final String id;
  final String title;
  final bool isActive;
  final String canonicalId;
  final int? sort;
  final String? emoji;

  // Legacy-compatible fields (unused for category icon rendering).
  final String iconName;
  final String iconAssetPath;
  final String? imageUrl;
  final String? imagePath;
  final Timestamp? updatedAt;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.isActive,
    required this.canonicalId,
    this.sort,
    this.emoji,
    this.iconName = 'category',
    required this.iconAssetPath,
    this.imageUrl,
    this.imagePath,
    this.updatedAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic>
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};
    final title = (data['title'] ?? data['name'] ?? '').toString();
    final themed = CategoryThemeCatalog.resolve(
      id: data['id']?.toString(),
      title: title,
    );

    return CategoryModel(
      id: (data['id'] ?? doc.id).toString(),
      title: title,
      isActive: data['isActive'] != false,
      canonicalId: themed.id,
      sort: data['sort'] is num
          ? (data['sort'] as num).toInt()
          : (data['order'] is num ? (data['order'] as num).toInt() : null),
      emoji: data['emoji']?.toString(),
      iconName: (data['iconName'] ?? 'category').toString(),
      iconAssetPath: themed.iconAssetPath,
      imageUrl: data['imageUrl']?.toString(),
      imagePath: data['imagePath']?.toString(),
      updatedAt: data['updatedAt'] as Timestamp?,
    );
  }

  String get name => title;
  int? get order => sort;

  String? get versionedImageUrl {
    final base = imageUrl;
    if (base == null || base.isEmpty) return null;
    final version = updatedAt?.millisecondsSinceEpoch;
    if (version == null) return base;
    final separator = base.contains('?') ? '&' : '?';
    return '$base${separator}v=$version';
  }
}
