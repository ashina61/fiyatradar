import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String? description;
  final String buttonText;
  final String? imageUrl;
  final String? badgeText;
  final bool isSponsor;
  final String? linkUrl;
  final bool isActive;
  final int order;
  final DateTime? createdAt;

  BannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.buttonText,
    this.imageUrl,
    this.badgeText,
    this.isSponsor = false,
    this.linkUrl,
    required this.isActive,
    required this.order,
    this.createdAt,
  });

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: m['title'] ?? '',
      description: m['description'] ?? '',
      buttonText: m['buttonText'] ?? 'KEŞFET',
      imageUrl: m['imageUrl'],
      badgeText: m['badgeText'],
      isSponsor: m['isSponsor'] ?? false,
      linkUrl: m['linkUrl'],
      isActive: m['isActive'] ?? false,
      order: m['order'] ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'description': description,
        'buttonText': buttonText,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (badgeText != null) 'badgeText': badgeText,
        'isSponsor': isSponsor,
        if (linkUrl != null) 'linkUrl': linkUrl,
        'isActive': isActive,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
