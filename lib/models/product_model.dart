import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String id;
  final String name;
  final String brand;
  final List<String> categories;
  final String? mainImage;
  final List<String> imageUrls;
  final String? imageUrl;
  final String? imageThumbUrl;
  final String? imageMediumUrl;
  final String? imagePath;
  final String imageSource;
  final bool aiGenerated;
  final String? aiPrompt;
  final bool imageApproved;
  final String? description;
  final String? barcode;
  final String? userId;
  final int viewCount;
  final int priceEntryCount;
  final double? lastPrice;
  final String? lastStore;
  final bool isEditorPick;
  final int? editorPickRank;
  final String? affiliateLink;
  final String? affiliateUrl;
  final String? buyLink;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    this.categories = const [],
    this.mainImage,
    this.imageUrls = const [],
    this.imageUrl,
    this.imageThumbUrl,
    this.imageMediumUrl,
    this.imagePath,
    this.imageSource = 'admin_manual',
    this.aiGenerated = false,
    this.aiPrompt,
    this.imageApproved = false,
    this.description,
    this.barcode,
    this.userId,
    this.viewCount = 0,
    this.priceEntryCount = 0,
    this.lastPrice,
    this.lastStore,
    this.isEditorPick = false,
    this.editorPickRank,
    this.affiliateLink,
    this.affiliateUrl,
    this.buyLink,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isTrending => priceEntryCount >= 10 || viewCount >= 100;

  /// Backward-compatible alias used by older UI widgets.
  double? get lowestPrice => lastPrice;

  String get category => categories.isNotEmpty ? categories.first : '';

  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final parsedCategories = _parseCategories(data);

    return ProductModel(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      categories: parsedCategories,
      mainImage: data['mainImage'] ?? data['imageThumbUrl'] ?? data['imageMediumUrl'] ?? data['imageUrl'],
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      imageUrl: data['imageUrl'] as String?,
      imageThumbUrl: data['imageThumbUrl'] as String?,
      imageMediumUrl: data['imageMediumUrl'] as String?,
      imagePath: data['imagePath'] as String?,
      imageSource: (data['imageSource'] ?? 'admin_manual').toString(),
      aiGenerated: data['aiGenerated'] == true,
      aiPrompt: data['aiPrompt'] as String?,
      imageApproved: data['imageApproved'] == true,
      description: data['description'],
      barcode: data['barcode'],
      userId: (data['userId'] ?? data['createdByUid']) as String?,
      viewCount: data['viewCount'] ?? 0,
      priceEntryCount: data['priceEntryCount'] ?? 0,
      lastPrice: (data['lastPrice'] as num?)?.toDouble(),
      lastStore: data['lastStore'],
      isEditorPick: data['isEditorPick'] == true,
      editorPickRank: data['editorPickRank'] is num
          ? (data['editorPickRank'] as num).toInt()
          : int.tryParse((data['editorPickRank'] ?? '').toString()),
      affiliateLink: _normalizedLink(data['affiliateLink']),
      affiliateUrl: _normalizedLink(data['affiliateUrl']),
      buyLink: (data['buyLink'] ?? '').toString().trim().isEmpty ? null : (data['buyLink']).toString().trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final normalizedName = name.trim().toLowerCase();
    return {
      'name': name,
      'name_lowercase': normalizedName,
      'searchKeywords': buildSearchKeywords(
        name: name,
        brand: brand,
        barcode: barcode,
        categories: categories,
      ),
      'brand': brand,
      'categories': categories,
      'category': categories.isNotEmpty ? categories.first : null,
      'mainImage': effectiveImage,
      'imageUrls': imageUrls,
      'imageUrl': imageUrl,
      'imageThumbUrl': imageThumbUrl,
      'imageMediumUrl': imageMediumUrl,
      'imagePath': imagePath,
      'imageSource': imageSource,
      'aiGenerated': aiGenerated,
      'aiPrompt': aiPrompt,
      'imageApproved': imageApproved,
      'description': description,
      'barcode': barcode,
      'userId': userId,
      'viewCount': viewCount,
      'priceEntryCount': priceEntryCount,
      'lastPrice': lastPrice,
      'lastStore': lastStore,
      'isEditorPick': isEditorPick,
      'editorPickRank': editorPickRank,
      'affiliateLink': affiliateLink,
      'affiliateUrl': affiliateUrl,
      'buyLink': buyLink,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? brand,
    List<String>? categories,
    String? mainImage,
    List<String>? imageUrls,
    String? imageUrl,
    String? imageThumbUrl,
    String? imageMediumUrl,
    String? imagePath,
    String? imageSource,
    bool? aiGenerated,
    String? aiPrompt,
    bool? imageApproved,
    String? description,
    String? barcode,
    String? userId,
    int? viewCount,
    int? priceEntryCount,
    double? lastPrice,
    String? lastStore,
    bool? isEditorPick,
    int? editorPickRank,
    String? affiliateLink,
    String? affiliateUrl,
    String? buyLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      categories: categories ?? this.categories,
      mainImage: mainImage ?? this.mainImage,
      imageUrls: imageUrls ?? this.imageUrls,
      imageUrl: imageUrl ?? this.imageUrl,
      imageThumbUrl: imageThumbUrl ?? this.imageThumbUrl,
      imageMediumUrl: imageMediumUrl ?? this.imageMediumUrl,
      imagePath: imagePath ?? this.imagePath,
      imageSource: imageSource ?? this.imageSource,
      aiGenerated: aiGenerated ?? this.aiGenerated,
      aiPrompt: aiPrompt ?? this.aiPrompt,
      imageApproved: imageApproved ?? this.imageApproved,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      userId: userId ?? this.userId,
      viewCount: viewCount ?? this.viewCount,
      priceEntryCount: priceEntryCount ?? this.priceEntryCount,
      lastPrice: lastPrice ?? this.lastPrice,
      lastStore: lastStore ?? this.lastStore,
      isEditorPick: isEditorPick ?? this.isEditorPick,
      editorPickRank: editorPickRank ?? this.editorPickRank,
      affiliateLink: affiliateLink ?? this.affiliateLink,
      affiliateUrl: affiliateUrl ?? this.affiliateUrl,
      buyLink: buyLink ?? this.buyLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseCategories(Map<String, dynamic> data) {
    final rawCategories = data['categories'];
    if (rawCategories is List) {
      final parsed = rawCategories
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      if (parsed.isNotEmpty) return parsed;
    }

    final legacyCategory = data['category']?.toString().trim() ?? '';
    if (legacyCategory.isNotEmpty) {
      return [legacyCategory];
    }
    return const [];
  }

  String? get effectiveImage {
    if (imageThumbUrl != null && imageThumbUrl!.isNotEmpty) return imageThumbUrl;
    if (imageMediumUrl != null && imageMediumUrl!.isNotEmpty) return imageMediumUrl;
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl;
    if (mainImage != null && mainImage!.isNotEmpty) return mainImage;
    if (imageUrls.isNotEmpty) return imageUrls.first;
    return null;
  }

  String? get preferredAffiliateUrl {
    final legacy = affiliateLink?.trim();
    if (legacy != null && legacy.isNotEmpty) return legacy;
    final primary = affiliateUrl?.trim();
    if (primary != null && primary.isNotEmpty) return primary;
    final fallback = buyLink?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  static String? _normalizedLink(Object? raw) {
    final value = (raw ?? '').toString().trim();
    return value.isEmpty ? null : value;
  }

  static List<String> buildSearchKeywords({
    required String name,
    required String brand,
    String? barcode,
    List<String> categories = const [],
  }) {
    final keywords = <String>{};

    void addKeyword(String raw) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty) return;
      keywords.add(normalized);
    }

    void addPrefixes(String raw) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.length < 2) return;
      for (var i = 2; i <= normalized.length; i++) {
        keywords.add(normalized.substring(0, i));
      }
    }

    void addPhraseTokens(String raw) {
      final normalized = raw.trim().toLowerCase();
      if (normalized.isEmpty) return;
      addKeyword(normalized);
      addPrefixes(normalized);

      final parts = normalized
          .split(RegExp(r'[^a-z0-9çğıöşü]+'))
          .map((part) => part.trim())
          .where((part) => part.isNotEmpty);
      for (final part in parts) {
        addKeyword(part);
        addPrefixes(part);
      }
    }

    addPhraseTokens(name);
    addPhraseTokens(brand);
    for (final category in categories) {
      addPhraseTokens(category);
    }
    if ((barcode ?? '').trim().isNotEmpty) {
      addKeyword(barcode!.trim());
    }

    return keywords.toList()..sort();
  }
}
