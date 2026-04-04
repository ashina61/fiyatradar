import 'package:flutter/material.dart';

class CategoryTheme {
  const CategoryTheme({
    required this.id,
    required this.title,
    required this.iconAssetPath,
    required this.accentColor,
    this.bgTint,
    required this.sortOrder,
  });

  final String id;
  final String title;
  final String iconAssetPath;
  final Color accentColor;
  final Color? bgTint;
  final int sortOrder;
}

class CategoryThemeCatalog {
  static const String assetsBasePath = 'assets/icons/categories/';

  // Place ultra premium glyph PNG category icons under:
  // assets/icons/categories/<category>.png
  static const List<CategoryTheme> themes = [
    CategoryTheme(
      id: 'temizlik',
      title: 'Temizlik',
      iconAssetPath: '${assetsBasePath}temizlik.png',
      accentColor: Color(0xFFC49A6A),
      bgTint: Color(0x14C49A6A),
      sortOrder: 1,
    ),
    CategoryTheme(
      id: 'kisisel_bakim',
      title: 'Kişisel Bakım',
      iconAssetPath: '${assetsBasePath}kisisel_bakim.png',
      accentColor: Color(0xFFB88458),
      bgTint: Color(0x12B88458),
      sortOrder: 2,
    ),
    CategoryTheme(
      id: 'kitap',
      title: 'Kitap',
      iconAssetPath: '${assetsBasePath}kitap.png',
      accentColor: Color(0xFF9E7652),
      bgTint: Color(0x109E7652),
      sortOrder: 3,
    ),
    CategoryTheme(
      id: 'spor',
      title: 'Spor',
      iconAssetPath: '${assetsBasePath}spor.png',
      accentColor: Color(0xFFAD7A49),
      bgTint: Color(0x12AD7A49),
      sortOrder: 4,
    ),
    CategoryTheme(
      id: 'gida',
      title: 'Gıda',
      iconAssetPath: '${assetsBasePath}gida.png',
      accentColor: Color(0xFFC18E5E),
      bgTint: Color(0x10C18E5E),
      sortOrder: 5,
    ),
    CategoryTheme(
      id: 'icecek',
      title: 'İçecek',
      iconAssetPath: '${assetsBasePath}icecek.png',
      accentColor: Color(0xFFBF8855),
      bgTint: Color(0x10BF8855),
      sortOrder: 6,
    ),
    CategoryTheme(
      id: 'atistirmalik',
      title: 'Atıştırmalık',
      iconAssetPath: '${assetsBasePath}atistirmalik.png',
      accentColor: Color(0xFFC79766),
      bgTint: Color(0x10C79766),
      sortOrder: 7,
    ),
    CategoryTheme(
      id: 'bebek',
      title: 'Bebek',
      iconAssetPath: '${assetsBasePath}bebek.png',
      accentColor: Color(0xFFC7A07A),
      bgTint: Color(0x10C7A07A),
      sortOrder: 8,
    ),
    CategoryTheme(
      id: 'ev_yasam',
      title: 'Ev & Yaşam',
      iconAssetPath: '${assetsBasePath}ev_yasam.png',
      accentColor: Color(0xFFB58A63),
      bgTint: Color(0x10B58A63),
      sortOrder: 9,
    ),
    CategoryTheme(
      id: 'elektronik',
      title: 'Elektronik',
      iconAssetPath: '${assetsBasePath}elektronik.png',
      accentColor: Color(0xFFA87955),
      bgTint: Color(0x10A87955),
      sortOrder: 10,
    ),
    CategoryTheme(
      id: 'evcil_hayvan',
      title: 'Evcil Hayvan',
      iconAssetPath: '${assetsBasePath}evcil_hayvan.png',
      accentColor: Color(0xFFB8875E),
      bgTint: Color(0x10B8875E),
      sortOrder: 11,
    ),
    CategoryTheme(
      id: 'diger',
      title: 'Diğer',
      iconAssetPath: '${assetsBasePath}temizlik.png',
      accentColor: Color(0xFFAF825D),
      bgTint: Color(0x10AF825D),
      sortOrder: 999,
    ),
  ];

  static final Map<String, CategoryTheme> _byId = {
    for (final theme in themes) theme.id: theme,
  };

  static String normalizeId(String value) {
    var normalized = value.trim().toLowerCase();
    const turkishMap = {
      'ı': 'i',
      'ğ': 'g',
      'ü': 'u',
      'ş': 's',
      'ö': 'o',
      'ç': 'c',
    };

    turkishMap.forEach((source, target) {
      normalized = normalized.replaceAll(source, target);
    });

    normalized = normalized
        .replaceAll('&', ' ')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return normalized;
  }

  static CategoryTheme resolve({String? id, String? title}) {
    final normalizedId = normalizeId(id ?? '');
    if (_byId.containsKey(normalizedId)) {
      return _byId[normalizedId]!;
    }

    final normalizedTitle = normalizeId(title ?? '');
    if (_byId.containsKey(normalizedTitle)) {
      return _byId[normalizedTitle]!;
    }

    return _byId['diger']!;
  }
}
