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
  final String? targetType;
  final String? targetId;
  final String? ctaText;
  final String? aspectRatio;
  final String? targetBasketId;
  final String? actionLabel;
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
    this.targetType,
    this.targetId,
    this.ctaText,
    this.aspectRatio,
    this.targetBasketId,
    this.actionLabel,
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
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return BannerModel(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle']?.toString(),
      description: data['description'],
      imageUrl: data['imageUrl'] ?? '',
      actionUrl: data['actionUrl'],
      productId: data['productId'],
      actionType: data['actionType']?.toString(),
      targetType: data['targetType']?.toString() ?? 'none',
      targetId: data['targetId']?.toString(),
      ctaText: data['ctaText']?.toString(),
      aspectRatio: data['aspectRatio']?.toString() ?? 'wide',
      targetBasketId:
          data['targetBasketId']?.toString() ?? data['targetId']?.toString(),
      actionLabel: data['actionLabel']?.toString(),
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
      'targetType': targetType,
      'targetId': targetId,
      'ctaText': ctaText,
      'aspectRatio': aspectRatio,
      'targetBasketId': targetBasketId,
      'actionLabel': actionLabel,
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
    String? targetType,
    String? targetId,
    String? ctaText,
    String? aspectRatio,
    String? targetBasketId,
    String? actionLabel,
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
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      ctaText: ctaText ?? this.ctaText,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      targetBasketId: targetBasketId ?? this.targetBasketId,
      actionLabel: actionLabel ?? this.actionLabel,
      targetProductIds: targetProductIds ?? this.targetProductIds,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}
