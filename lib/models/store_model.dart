import 'package:cloud_firestore/cloud_firestore.dart';

enum StoreStatus { active, hidden, pending }
enum StoreType { store, onlineStore }

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
  final String storeType;
  final bool? legacyIsOnline;
  final bool isTemporary;
  final bool isRecurring;
  final String? addressText;
  final List<String> searchKeywords;
  final DateTime createdAt;
  final DateTime? updatedAt;

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
    this.type = StoreType.store,
    this.storeType = 'store',
    this.legacyIsOnline,
    this.isTemporary = false,
    this.isRecurring = false,
    this.addressText,
    this.searchKeywords = const [],
    required this.createdAt,
    this.updatedAt,
  });

  GeoPoint get geoPoint => GeoPoint(lat, lng);
  String get name => displayName;
  bool get isOnline => type == StoreType.onlineStore || legacyIsOnline == true;

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return StoreModel.fromMap(data, id: doc.id);
  }

  factory StoreModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    final coordinates = _extractCoordinates(data);

    return StoreModel(
      id: id.isNotEmpty ? id : (data['id']?.toString() ?? ''),
      brandId: data['brandId']?.toString(),
      displayName: _parseDisplayName(data),
      city: data['city']?.toString() ?? '',
      district: data['district']?.toString() ?? '',
      neighborhood: data['neighborhood']?.toString() ?? '',
      address: data['address']?.toString(),
      addressText: data['addressText']?.toString(),
      lat: coordinates.$1,
      lng: coordinates.$2,
      status: _parseStatus(data['status']?.toString()),
      type: _parseType(data),
      storeType: _normalizeStoreType(data),
      legacyIsOnline: data['isOnline'] as bool?,
      isTemporary: data['isTemporary'] as bool? ?? false,
      isRecurring: data['isRecurring'] as bool? ?? false,
      searchKeywords: _parseStringList(data['searchKeywords']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
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
      'addressText': addressText ?? address,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      'type': _legacyTypeName(type),
      'storeType': storeType,
      'isOnline': isOnline,
      'isTemporary': isTemporary,
      'isRecurring': isRecurring,
      'searchKeywords': searchKeywords,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        ...toFirestore(),
      };

  static StoreType _parseType(Map<String, dynamic> data) {
    final storeType = _normalizeStoreType(data);
    switch (storeType) {
      case 'online_store':
        return StoreType.onlineStore;
      case 'store':
      default:
        break;
    }
    final normalized = data['type']?.toString();
    switch (normalized) {
      case 'online':
        return StoreType.onlineStore;
      case 'local':
      case 'store':
      default:
        return StoreType.store;
    }
  }

  static String _legacyTypeName(StoreType type) {
    switch (type) {
      case StoreType.onlineStore:
        return 'online';
      case StoreType.store:
        return 'local';
    }
  }

  static String _normalizeStoreType(Map<String, dynamic> data) {
    final raw = data['storeType']?.toString().trim();
    if (raw == 'store' || raw == 'online_store') {
      return raw!;
    }
    final legacyType = data['type']?.toString().trim();
    if (legacyType == 'online' || data['isOnline'] == true) return 'online_store';
    return 'store';
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
    String? storeType,
    bool? legacyIsOnline,
    bool? isTemporary,
    bool? isRecurring,
    String? addressText,
    List<String>? searchKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      storeType: storeType ?? this.storeType,
      legacyIsOnline: legacyIsOnline ?? this.legacyIsOnline,
      isTemporary: isTemporary ?? this.isTemporary,
      isRecurring: isRecurring ?? this.isRecurring,
      addressText: addressText ?? this.addressText,
      searchKeywords: searchKeywords ?? this.searchKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<String> _parseStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  static String _parseDisplayName(Map<String, dynamic> data) {
    final displayName = data['displayName']?.toString().trim() ?? '';
    if (displayName.isNotEmpty) return displayName;
    final name = data['name']?.toString().trim() ?? '';
    if (name.isNotEmpty) return name;
    final branchName = data['branchName']?.toString().trim() ?? '';
    if (branchName.isNotEmpty) return branchName;
    final storeName = data['storeName']?.toString().trim() ?? '';
    if (storeName.isNotEmpty) return storeName;
    return '';
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
