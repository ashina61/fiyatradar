import 'package:cloud_firestore/cloud_firestore.dart';

enum BannerType { duyuru, sponsor, kampanya }

class BannerModel {
  const BannerModel({
    required this.id,
    required this.title,
    this.type = BannerType.duyuru,
    this.subtitle = '',
    this.description,
    this.ctaLabel = 'Keşfet',
    this.ctaText,
    this.tagLabel = 'Duyuru',
    this.badgeText,
    this.isActive = false,
    this.order = 0,
    this.imageUrl,
    this.brandName,
    this.metaLabel,
    this.linkUrl,
    this.actionUrl,
    this.targetType,
    this.targetId,
    this.aspectRatio,
    this.createdAt,
  });

  final String id;
  final BannerType type;
  final String title;
  final String subtitle;
  final String? description;
  final String ctaLabel;
  final String? ctaText;
  final String tagLabel;
  final String? badgeText;
  final bool isActive;
  final int order;
  final String? imageUrl;
  final String? brandName;
  final String? metaLabel;
  final String? linkUrl;
  final String? actionUrl;
  final String? targetType;
  final String? targetId;
  final String? aspectRatio;
  final DateTime? createdAt;

  bool get shouldShow => isActive;

  factory BannerModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    return BannerModel.fromMap(doc.id, doc.data() ?? const <String, dynamic>{});
  }

  factory BannerModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data();
    return BannerModel.fromMap(
      doc.id,
      data is Map<String, dynamic> ? data : const <String, dynamic>{},
    );
  }

  factory BannerModel.fromMap(String id, Map<String, dynamic> m) {
    final resolvedTargetType = (m['targetType'] as String?) ?? (m['type'] as String?) ?? 'duyuru';
    final normalizedType = resolvedTargetType.toLowerCase();
    final resolvedType = switch (normalizedType) {
      'sponsor' => BannerType.sponsor,
      'kampanya' => BannerType.kampanya,
      _ => BannerType.duyuru,
    };

    final resolvedDescription = (m['description'] as String?) ?? (m['subtitle'] as String?);
    final resolvedCtaText = (m['ctaText'] as String?) ?? (m['ctaLabel'] as String?);
    final resolvedBadgeText = (m['badgeText'] as String?) ?? (m['tagLabel'] as String?) ?? (m['metaLabel'] as String?);

    return BannerModel(
      id: id,
      type: resolvedType,
      title: m['title'] as String? ?? '',
      subtitle: m['subtitle'] as String? ?? resolvedDescription ?? '',
      description: resolvedDescription,
      ctaLabel: m['ctaLabel'] as String? ?? resolvedCtaText ?? 'Keşfet',
      ctaText: resolvedCtaText,
      tagLabel: m['tagLabel'] as String? ?? resolvedBadgeText ?? 'Duyuru',
      badgeText: resolvedBadgeText,
      isActive: m['isActive'] as bool? ?? false,
      order: (m['order'] as num?)?.toInt() ?? 0,
      imageUrl: m['imageUrl'] as String?,
      brandName: m['brandName'] as String?,
      metaLabel: m['metaLabel'] as String?,
      linkUrl: m['linkUrl'] as String?,
      actionUrl: m['actionUrl'] as String?,
      targetType: m['targetType'] as String? ?? m['type'] as String?,
      targetId: m['targetId'] as String?,
      aspectRatio: m['aspectRatio'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'type': targetType ?? type.name,
        'title': title,
        'subtitle': subtitle,
        'description': description ?? subtitle,
        'ctaLabel': ctaLabel,
        'ctaText': ctaText ?? ctaLabel,
        'tagLabel': tagLabel,
        'badgeText': badgeText ?? tagLabel,
        'isActive': isActive,
        'order': order,
        if (imageUrl != null) 'imageUrl': imageUrl,
        if (brandName != null) 'brandName': brandName,
        if (metaLabel != null) 'metaLabel': metaLabel,
        if (linkUrl != null) 'linkUrl': linkUrl,
        if (actionUrl != null) 'actionUrl': actionUrl,
        if (targetType != null) 'targetType': targetType,
        if (targetId != null) 'targetId': targetId,
        if (aspectRatio != null) 'aspectRatio': aspectRatio,
        'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toMap() => toFirestore();
}
