import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SpecialListItemModel {
  const SpecialListItemModel({
    required this.id,
    required this.productId,
    required this.productNameSnapshot,
    required this.productBrandSnapshot,
    this.productImageUrlSnapshot,
    required this.quantityLabel,
    required this.tagLabel,
    this.selectedStoreId,
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
  final String? productImageUrlSnapshot;
  final String quantityLabel;
  final String tagLabel;
  final String? selectedStoreId;
  final String selectedStoreNameSnapshot;
  final String selectedStoreColor;
  final double selectedPrice;
  final int sortOrder;
  final bool isActive;

  factory SpecialListItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return SpecialListItemModel(
      id: doc.id,
      productId: (data['productId'] ?? '').toString(),
      productNameSnapshot: (data['productNameSnapshot'] ?? '').toString(),
      productBrandSnapshot: (data['productBrandSnapshot'] ?? '').toString(),
      productImageUrlSnapshot: data['productImageUrlSnapshot']?.toString(),
      quantityLabel: (data['quantityLabel'] ?? '').toString(),
      tagLabel: (data['tagLabel'] ?? '').toString(),
      selectedStoreId: data['selectedStoreId']?.toString(),
      selectedStoreNameSnapshot: (data['selectedStoreNameSnapshot'] ?? '').toString(),
      selectedStoreColor: (data['selectedStoreColor'] ?? '#18100A').toString(),
      selectedPrice: (data['selectedPrice'] as num?)?.toDouble() ?? 0,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] == true,
    );
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

  Color get marketColor => _colorFromHex(selectedStoreColor);

  static Color _colorFromHex(String value) {
    final normalized = value.replaceAll('#', '').trim();
    if (normalized.length == 6) {
      final parsed = int.tryParse('FF$normalized', radix: 16);
      if (parsed != null) return Color(parsed);
    }
    if (normalized.length == 8) {
      final parsed = int.tryParse(normalized, radix: 16);
      if (parsed != null) return Color(parsed);
    }
    return const Color(0xFF18100A);
  }
}
