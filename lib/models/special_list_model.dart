import 'package:cloud_firestore/cloud_firestore.dart';

enum SpecialListCtaActionType {
  compareCart('compare_cart'),
  openProductList('open_product_list'),
  openCampaign('open_campaign'),
  none('none');

  const SpecialListCtaActionType(this.value);
  final String value;

  static SpecialListCtaActionType fromValue(String? value) {
    return SpecialListCtaActionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SpecialListCtaActionType.none,
    );
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
      title: (data['title'] ?? '').toString(),
      subtitle: (data['subtitle'] ?? '').toString(),
      badgeText: (data['badgeText'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      coverType: (data['coverType'] ?? 'default').toString(),
      coverImageUrl: data['coverImageUrl']?.toString(),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0,
      savingsAmount: (data['savingsAmount'] as num?)?.toDouble() ?? 0,
      savingsLabel: (data['savingsLabel'] ?? '').toString(),
      bestMarketName: (data['bestMarketName'] ?? '').toString(),
      ctaText: (data['ctaText'] ?? 'Sepeti Kıyasla').toString(),
      ctaActionType: SpecialListCtaActionType.fromValue(data['ctaActionType']?.toString()),
      isActive: data['isActive'] != false,
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

  String get heroTitle => subtitle.trim().isNotEmpty ? subtitle.trim() : title;
}
