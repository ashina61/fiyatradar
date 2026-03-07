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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
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
}
