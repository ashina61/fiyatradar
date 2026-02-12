import 'package:cloud_firestore/cloud_firestore.dart';

class BannerModel {
  final String id;
  final String title;
  final String? subtitle;
  final String? description;
  final String imageUrl;
  final String? actionUrl;
  final String? productId;
  final String? actionType;
  final String? targetId;
  final String? targetBasketId;
  final List<String> targetProductIds;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime? expiresAt;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.description,
    required this.imageUrl,
    this.actionUrl,
    this.productId,
    this.actionType,
    this.targetId,
    this.targetBasketId,
    this.targetProductIds = const [],
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
      subtitle: data['subtitle']?.toString(),
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      productId: data['productId'],
      actionType: data['actionType']?.toString(),
      targetId: data['targetId']?.toString(),
      targetBasketId:
          data['targetBasketId']?.toString() ?? data['targetId']?.toString(),
      targetProductIds: List<String>.from(data['targetProductIds'] ?? const []),
      isActive: data['isActive'] ?? true,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'productId': productId,
      'actionType': actionType,
      'targetId': targetId,
      'targetBasketId': targetBasketId,
      'targetProductIds': targetProductIds,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? description,
    String? imageUrl,
    String? actionUrl,
    String? productId,
    String? actionType,
    String? targetId,
    String? targetBasketId,
    List<String>? targetProductIds,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      actionUrl: actionUrl ?? this.actionUrl,
      productId: productId ?? this.productId,
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      targetBasketId: targetBasketId ?? this.targetBasketId,
      targetProductIds: targetProductIds ?? this.targetProductIds,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
