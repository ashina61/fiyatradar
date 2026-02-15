import 'package:cloud_firestore/cloud_firestore.dart';

class ActualModel {
  final String id;
  final String title;
  final String marketId;
  final String marketName;
  final DateTime startDate;
  final DateTime endDate;
  final String coverImageUrl;
  final String description;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ActualModel({
    required this.id,
    required this.title,
    required this.marketId,
    required this.marketName,
    required this.startDate,
    required this.endDate,
    required this.coverImageUrl,
    required this.description,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActualModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return ActualModel(
      id: doc.id,
      title: (data['title'] as String?)?.trim() ?? '',
      marketId: (data['marketId'] as String?)?.trim() ?? '',
      marketName: (data['marketName'] as String?)?.trim() ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
      description: (data['description'] as String?)?.trim() ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'marketId': marketId,
      'marketName': marketName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'coverImageUrl': coverImageUrl,
      'description': description,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  ActualModel copyWith({
    String? id,
    String? title,
    String? marketId,
    String? marketName,
    DateTime? startDate,
    DateTime? endDate,
    String? coverImageUrl,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActualModel(
      id: id ?? this.id,
      title: title ?? this.title,
      marketId: marketId ?? this.marketId,
      marketName: marketName ?? this.marketName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
