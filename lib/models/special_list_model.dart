import 'package:cloud_firestore/cloud_firestore.dart';

enum SpecialListCtaActionType {
  compareCart('compare_cart'),
  openProductList('open_product_list'),
  openCampaign('open_campaign'),
  none('none');

  const SpecialListCtaActionType(this.value);
  final String value;

  static SpecialListCtaActionType fromString(String? value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    return SpecialListCtaActionType.none;
  }
}

class SpecialListModel {
  const SpecialListModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.description,
    required this.coverType,
    this.coverImageUrl,
    required this.totalPrice,
    required this.savingsAmount,
    required this.savingsLabel,
    required this.bestMarketName,
    required this.ctaText,
    required this.ctaActionType,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String description;
  final String coverType;
  final String? coverImageUrl;
  final double totalPrice;
  final double savingsAmount;
  final String savingsLabel;
  final String bestMarketName;
  final String ctaText;
  final SpecialListCtaActionType ctaActionType;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SpecialListModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SpecialListModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      subtitle: data['subtitle']?.toString() ?? '',
      badgeText: data['badgeText']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      coverType: data['coverType']?.toString() ?? 'gradient',
      coverImageUrl: data['coverImageUrl']?.toString(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      savingsAmount: (data['savingsAmount'] as num?)?.toDouble() ?? 0,
      savingsLabel: data['savingsLabel']?.toString() ?? '',
      bestMarketName: data['bestMarketName']?.toString() ?? '',
      ctaText: data['ctaText']?.toString() ?? 'Sepeti Kıyasla',
      ctaActionType: SpecialListCtaActionType.fromString(data['ctaActionType']?.toString()),
      isActive: data['isActive'] == true,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'badgeText': badgeText,
      'description': description,
      'coverType': coverType,
      'coverImageUrl': coverImageUrl,
      'totalPrice': totalPrice,
      'savingsAmount': savingsAmount,
      'savingsLabel': savingsLabel,
      'bestMarketName': bestMarketName,
      'ctaText': ctaText,
      'ctaActionType': ctaActionType.value,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  SpecialListModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badgeText,
    String? description,
    String? coverType,
    String? coverImageUrl,
    double? totalPrice,
    double? savingsAmount,
    String? savingsLabel,
    String? bestMarketName,
    String? ctaText,
    SpecialListCtaActionType? ctaActionType,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpecialListModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badgeText: badgeText ?? this.badgeText,
      description: description ?? this.description,
      coverType: coverType ?? this.coverType,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      totalPrice: totalPrice ?? this.totalPrice,
      savingsAmount: savingsAmount ?? this.savingsAmount,
      savingsLabel: savingsLabel ?? this.savingsLabel,
      bestMarketName: bestMarketName ?? this.bestMarketName,
      ctaText: ctaText ?? this.ctaText,
      ctaActionType: ctaActionType ?? this.ctaActionType,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
