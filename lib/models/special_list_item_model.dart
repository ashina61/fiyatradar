import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';

class SpecialListItemModel {
  const SpecialListItemModel({
    required this.id,
    required this.productId,
    required this.productNameSnapshot,
    required this.productBrandSnapshot,
    required this.productImageUrlSnapshot,
    required this.quantityLabel,
    required this.tagLabel,
    required this.selectedStoreId,
    required this.selectedStoreNameSnapshot,
    required this.selectedStoreColor,
    required this.selectedPrice,
    required this.sortOrder,
    required this.isActive,
  });

  final String id;
  final String productId;
  final String productNameSnapshot;
  final String productBrandSnapshot;
  final String productImageUrlSnapshot;
  final String quantityLabel;
  final String tagLabel;
  final String selectedStoreId;
  final String selectedStoreNameSnapshot;
  final String selectedStoreColor;
  final double selectedPrice;
  final int sortOrder;
  final bool isActive;

  factory SpecialListItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SpecialListItemModel(
      id: doc.id,
      productId: data['productId']?.toString() ?? '',
      productNameSnapshot: data['productNameSnapshot']?.toString() ?? '',
      productBrandSnapshot: data['productBrandSnapshot']?.toString() ?? '',
      productImageUrlSnapshot: data['productImageUrlSnapshot']?.toString() ?? '',
      quantityLabel: data['quantityLabel']?.toString() ?? '',
      tagLabel: data['tagLabel']?.toString() ?? '',
      selectedStoreId: data['selectedStoreId']?.toString() ?? '',
      selectedStoreNameSnapshot: data['selectedStoreNameSnapshot']?.toString() ?? '',
      selectedStoreColor: data['selectedStoreColor']?.toString() ?? '#D0A278',
      selectedPrice: (data['selectedPrice'] as num?)?.toDouble() ?? 0,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] != false,
    );
  }

  Color get marketColor {
    try {
      return Color(int.parse(selectedStoreColor.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFFD0A278);
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'productNameSnapshot': productNameSnapshot,
      'productBrandSnapshot': productBrandSnapshot,
      'productImageUrlSnapshot': productImageUrlSnapshot,
      'quantityLabel': quantityLabel,
      'tagLabel': tagLabel,
      'selectedStoreId': selectedStoreId,
      'selectedStoreNameSnapshot': selectedStoreNameSnapshot,
      'selectedStoreColor': selectedStoreColor,
      'selectedPrice': selectedPrice,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  SpecialListItemModel copyWith({
    String? id,
    String? productId,
    String? productNameSnapshot,
    String? productBrandSnapshot,
    String? productImageUrlSnapshot,
    String? quantityLabel,
    String? tagLabel,
    String? selectedStoreId,
    String? selectedStoreNameSnapshot,
    String? selectedStoreColor,
    double? selectedPrice,
    int? sortOrder,
    bool? isActive,
  }) {
    return SpecialListItemModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productNameSnapshot: productNameSnapshot ?? this.productNameSnapshot,
      productBrandSnapshot: productBrandSnapshot ?? this.productBrandSnapshot,
      productImageUrlSnapshot: productImageUrlSnapshot ?? this.productImageUrlSnapshot,
      quantityLabel: quantityLabel ?? this.quantityLabel,
      tagLabel: tagLabel ?? this.tagLabel,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      selectedStoreNameSnapshot: selectedStoreNameSnapshot ?? this.selectedStoreNameSnapshot,
      selectedStoreColor: selectedStoreColor ?? this.selectedStoreColor,
      selectedPrice: selectedPrice ?? this.selectedPrice,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}
