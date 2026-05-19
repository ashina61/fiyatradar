import 'package:flutter/foundation.dart';

/// One brand-agnostic illustration entry from
/// `assets/illustrations/manifest.json`. These illustrations represent
/// product categories, not specific brands, and are used as the default
/// visual for catalog entries until a moderator-approved photo replaces
/// them.
@immutable
class IllustrationAsset {
  final String id;
  final String fileName;
  final String category;
  final String categoryLabel;
  final String label;
  final List<String> tags;

  const IllustrationAsset({
    required this.id,
    required this.fileName,
    required this.category,
    required this.categoryLabel,
    required this.label,
    required this.tags,
  });

  String get assetPath => 'assets/illustrations/$fileName';

  factory IllustrationAsset.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags.map((e) => e.toString()).toList(growable: false)
        : const <String>[];
    return IllustrationAsset(
      id: (json['id'] ?? '') as String,
      fileName: (json['fileName'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      categoryLabel: (json['categoryLabel'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      tags: tags,
    );
  }
}

@immutable
class IllustrationCategory {
  final String id;
  final String label;
  final String icon;

  const IllustrationCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  factory IllustrationCategory.fromJson(Map<String, dynamic> json) {
    return IllustrationCategory(
      id: (json['id'] ?? '') as String,
      label: (json['label'] ?? '') as String,
      icon: (json['icon'] ?? 'category') as String,
    );
  }
}

@immutable
class IllustrationManifest {
  final String version;
  final List<IllustrationAsset> illustrations;
  final List<IllustrationCategory> categories;

  const IllustrationManifest({
    required this.version,
    required this.illustrations,
    required this.categories,
  });
}
