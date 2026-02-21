import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreStatus { active, hidden, pending }
enum StoreType { local, online }

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
  final StoreType type;
  final bool? legacyIsOnline;
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
    this.type = StoreType.local,
    this.legacyIsOnline,
    required this.createdAt,
  });

  GeoPoint get geoPoint => GeoPoint(lat, lng);

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    final coordinates = _extractCoordinates(data);

    return StoreModel(
      id: doc.id,
      brandId: data['brandId'],
      displayName: _parseDisplayName(data),
      city: data['city'] ?? '',
      district: data['district'] ?? '',
      neighborhood: data['neighborhood'] ?? '',
      address: data['address'],
      lat: coordinates.$1,
      lng: coordinates.$2,
      status: _parseStatus(data['status']),
      type: _parseType(data['type']),
      legacyIsOnline: data['isOnline'] as bool?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'brandId': brandId,
      'displayName': displayName,
      'name': displayName,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'address': address,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      'type': type.name,
      'isOnline': type == StoreType.online,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static StoreType _parseType(dynamic value) {
    final normalized = value?.toString();
    switch (normalized) {
      case 'online':
        return StoreType.online;
      case 'local':
      default:
        return StoreType.local;
    }
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
    StoreType? type,
    bool? legacyIsOnline,
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
      type: type ?? this.type,
      legacyIsOnline: legacyIsOnline ?? this.legacyIsOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOnline => type == StoreType.online || legacyIsOnline == true;

  static String _parseDisplayName(Map<String, dynamic> data) {
    final displayName = data['displayName']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    return data['name']?.toString().trim() ?? '';
  }

  static (double, double) _extractCoordinates(Map<String, dynamic> data) {
    final directLat = _toDouble(data['lat']);
    final directLng = _toDouble(data['lng']);
    if (directLat != null && directLng != null) {
      return (directLat, directLng);
    }

    final geoPoint = data['geoPoint'] ?? data['location'] ?? data['coordinates'] ?? data['geo'];
    if (geoPoint is GeoPoint) {
      return (geoPoint.latitude, geoPoint.longitude);
    }

    if (geoPoint is Map) {
      final map = Map<String, dynamic>.from(geoPoint);
      final mapLat = _toDouble(map['lat'] ?? map['latitude']);
      final mapLng = _toDouble(map['lng'] ?? map['longitude'] ?? map['lon']);
      if (mapLat != null && mapLng != null) {
        return (mapLat, mapLng);
      }
    }

    if (geoPoint is String) {
      final match = RegExp(r'-?\d+(?:\.\d+)?').allMatches(geoPoint).map((m) => m.group(0)).toList();
      if (match.length >= 2) {
        final strLat = double.tryParse(match[0] ?? '');
        final strLng = double.tryParse(match[1] ?? '');
        if (strLat != null && strLng != null) {
          return (strLat, strLng);
        }
      }
    }

    return (0.0, 0.0);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(',', '.').trim();
      return double.tryParse(normalized);
    }
    return null;
  }
}
