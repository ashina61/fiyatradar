import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreSuggestionStatus { pending, approved, merged, rejected }

class StoreSuggestionModel {
  final String id;
  final String displayName;
  final double lat;
  final double lng;
  final String city;
  final String district;
  final String neighborhood;
  final StoreSuggestionStatus status;
  final String? resolvedStoreId;
  final DateTime createdAt;

  StoreSuggestionModel({
    required this.id,
    required this.displayName,
    required this.lat,
    required this.lng,
    this.city = '',
    this.district = '',
    this.neighborhood = '',
    this.status = StoreSuggestionStatus.pending,
    this.resolvedStoreId,
    required this.createdAt,
  });

  factory StoreSuggestionModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return StoreSuggestionModel(
      id: doc.id,
      displayName: (data['displayName'] ?? '').toString(),
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      city: (data['city'] ?? '').toString(),
      district: (data['district'] ?? '').toString(),
      neighborhood: (data['neighborhood'] ?? '').toString(),
      status: _parseStatus(data['status'] as String?),
      resolvedStoreId: data['resolvedStoreId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'lat': lat,
      'lng': lng,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'status': status.name,
      'resolvedStoreId': resolvedStoreId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static StoreSuggestionStatus _parseStatus(String? value) {
    switch (value) {
      case 'approved':
        return StoreSuggestionStatus.approved;
      case 'merged':
        return StoreSuggestionStatus.merged;
      case 'rejected':
        return StoreSuggestionStatus.rejected;
      case 'pending':
      default:
        return StoreSuggestionStatus.pending;
    }
  }
}
