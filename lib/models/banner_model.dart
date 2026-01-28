import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final String? actionUrl;
  final String? productId;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime? expiresAt;

  BannerModel({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    this.actionUrl,
    this.productId,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get shouldShow => isActive && !isExpired;

  factory BannerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      productId: data['productId'],
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'productId': productId,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? actionUrl,
    String? productId,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      productId: productId ?? this.productId,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
