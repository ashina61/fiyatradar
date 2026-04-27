import 'package:cloud_firestore/cloud_firestore.dart';

enum StorePlaceType { chainMarket, localMarket, onlineMarket, bazaar }

StorePlaceType storePlaceTypeFromString(String? raw) {
  switch (raw) {
    case 'chain_market':
      return StorePlaceType.chainMarket;
    case 'local_market':
      return StorePlaceType.localMarket;
    case 'online_market':
      return StorePlaceType.onlineMarket;
    case 'bazaar':
      return StorePlaceType.bazaar;
    default:
      return StorePlaceType.localMarket;
  }
}

String storePlaceTypeToString(StorePlaceType type) {
  switch (type) {
    case StorePlaceType.chainMarket:
      return 'chain_market';
    case StorePlaceType.localMarket:
      return 'local_market';
    case StorePlaceType.onlineMarket:
      return 'online_market';
    case StorePlaceType.bazaar:
      return 'bazaar';
  }
}

enum PriceSourceType { physical, online, bazaar }

String priceSourceTypeToString(PriceSourceType sourceType) {
  switch (sourceType) {
    case PriceSourceType.physical:
      return 'physical';
    case PriceSourceType.online:
      return 'online';
    case PriceSourceType.bazaar:
      return 'bazaar';
  }
}

String scopeForSourceType(PriceSourceType sourceType) {
  switch (sourceType) {
    case PriceSourceType.physical:
      return 'local';
    case PriceSourceType.online:
      return 'online';
    case PriceSourceType.bazaar:
      return 'bazaar';
  }
}

class StorePlace {
  final String id;
  final String? chainId;
  final String? chainName;
  final StorePlaceType type;
  final String displayName;
  final String normalizedName;
  final String city;
  final String district;
  final String? neighborhood;
  final double? lat;
  final double? lng;
  final String status;
  final bool isActive;

  const StorePlace({
    required this.id,
    required this.type,
    required this.displayName,
    required this.normalizedName,
    required this.city,
    required this.district,
    required this.status,
    required this.isActive,
    this.chainId,
    this.chainName,
    this.neighborhood,
    this.lat,
    this.lng,
  });

  factory StorePlace.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? <String, dynamic>{};
    return StorePlace(
      id: doc.id,
      chainId: (m['chainId'] as String?)?.trim().isNotEmpty == true
          ? (m['chainId'] as String)
          : null,
      chainName: (m['chainName'] as String?)?.trim().isNotEmpty == true
          ? (m['chainName'] as String)
          : null,
      type: storePlaceTypeFromString(m['type'] as String?),
      displayName: (m['displayName'] ?? '') as String,
      normalizedName: (m['normalizedName'] ?? '') as String,
      city: (m['city'] ?? '') as String,
      district: (m['district'] ?? '') as String,
      neighborhood: m['neighborhood'] as String?,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      status: (m['status'] ?? 'pending') as String,
      isActive: (m['isActive'] as bool?) ?? true,
    );
  }
}
