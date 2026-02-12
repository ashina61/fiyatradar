import 'package:cloud_firestore/cloud_firestore.dart';

class CampaignBasketModel {
  final String id;
  final String title;
  final String description;
  final String? imageUrl;
  final bool isActive;
  final List<String> itemProductIds;
  final int? sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;

  const CampaignBasketModel({
    required this.id,
    required this.title,
    required this.description,
    this.imageUrl,
    this.isActive = true,
    this.itemProductIds = const [],
    this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory CampaignBasketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? <String, dynamic>{};
    return CampaignBasketModel(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      imageUrl: data['imageUrl']?.toString(),
      isActive: data['isActive'] as bool? ?? true,
      itemProductIds: List<String>.from(data['itemProductIds'] ?? const []),
      sortOrder: (data['sortOrder'] as num?)?.toInt(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'itemProductIds': itemProductIds,
      'sortOrder': sortOrder,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CampaignBasketModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    bool? isActive,
    List<String>? itemProductIds,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return CampaignBasketModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      itemProductIds: itemProductIds ?? this.itemProductIds,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
