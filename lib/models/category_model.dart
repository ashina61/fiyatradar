import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String title;
  final bool isActive;
  final int? sort;
  final String? emoji;

  // Legacy-compatible fields (unused for category icon rendering).
  final String iconName;
  final String? imageUrl;
  final String? imagePath;
  final Timestamp? updatedAt;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.isActive,
    this.sort,
    this.emoji,
    this.iconName = 'category',
    this.imageUrl,
    this.imagePath,
    this.updatedAt,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return CategoryModel(
      id: (data['id'] ?? doc.id).toString(),
      title: (data['title'] ?? data['name'] ?? '').toString(),
      isActive: data['isActive'] != false,
      sort: data['sort'] is num
          ? (data['sort'] as num).toInt()
          : (data['order'] is num ? (data['order'] as num).toInt() : null),
      emoji: data['emoji']?.toString(),
      iconName: (data['iconName'] ?? 'category').toString(),
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
