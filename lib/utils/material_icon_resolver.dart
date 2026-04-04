import 'package:flutter/material.dart';

/// Resolves Firestore `iconName` values to Material icons.
IconData materialIconFromName(String? iconName) {
  final normalized = (iconName ?? '').trim().toLowerCase();

  const iconMap = <String, IconData>{
    'shopping_cart': Icons.shopping_cart,
    'fastfood': Icons.fastfood,
    'local_mall': Icons.local_mall,
    'sports_soccer': Icons.sports_soccer,
    'devices': Icons.devices,
    'restaurant': Icons.restaurant,
    'cleaning_services': Icons.cleaning_services,
    'face': Icons.face,
    'home': Icons.home,
    'checkroom': Icons.checkroom,
    'sports': Icons.sports,
    'toys': Icons.toys,
    'book': Icons.book,
    'directions_car': Icons.directions_car,
    'category': Icons.category,
  };

  return iconMap[normalized] ?? Icons.category;
}

