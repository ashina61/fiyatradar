import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreStatus { active, hidden, pending }

class StoreModel {
  final String id;
  final String? brandId;
  final String displayName;
  final String city;
  final String district;
  final String neighborhood;
  final String? address;
  final double lat;
  final double lng;
  final StoreStatus status;
  final DateTime createdAt;

  StoreModel({
    required this.id,
    this.brandId,
    required this.displayName,
    required this.city,
    required this.district,
    required this.neighborhood,
    this.address,
    required this.lat,
    required this.lng,
    this.status = StoreStatus.active,
    required this.createdAt,
  });

  GeoPoint get geoPoint => GeoPoint(lat, lng);

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      brandId: data['brandId'],
      displayName: data['displayName'] ?? data['name'] ?? '',
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      address: data['address'],
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      status: _parseStatus(data['status']),
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brandId': brandId,
      'displayName': displayName,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static StoreStatus _parseStatus(String? value) {
    switch (value) {
      case 'active':
        return StoreStatus.active;
      case 'hidden':
        return StoreStatus.hidden;
      case 'pending':
        return StoreStatus.pending;
      default:
        return StoreStatus.active;
    }
  }

  String get statusLabel {
    switch (status) {
      case StoreStatus.active:
        return 'Aktif';
      case StoreStatus.hidden:
        return 'Gizli';
      case StoreStatus.pending:
        return 'Onay Bekliyor';
    }
  }

  StoreModel copyWith({
    String? id,
    String? brandId,
    String? displayName,
    String? city,
    String? district,
    String? neighborhood,
    String? address,
    double? lat,
    double? lng,
    StoreStatus? status,
    DateTime? createdAt,
  }) {
    return StoreModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      displayName: displayName ?? this.displayName,
      city: city ?? this.city,
      district: district ?? this.district,
      neighborhood: neighborhood ?? this.neighborhood,
      address: address ?? this.address,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
