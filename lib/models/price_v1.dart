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

/// Canonical day-of-week tokens used for neighborhood bazaars. Stored as
/// lowercase English strings so the schema is locale-independent; the UI
/// converts to Turkish labels via [bazaarDayLabelTr].
const List<String> kBazaarDayTokens = <String>[
  'monday',
  'tuesday',
  'wednesday',
  'thursday',
  'friday',
  'saturday',
  'sunday',
];

/// Maps a [DateTime.weekday] (1..7) to the canonical token used in the
/// `marketDays` field on a `store_places` bazaar doc.
String bazaarDayTokenForWeekday(int weekday) {
  final idx = ((weekday - 1) % 7).clamp(0, 6);
  return kBazaarDayTokens[idx];
}

String bazaarDayLabelTr(String token) {
  switch (token) {
    case 'monday':
      return 'Pazartesi';
    case 'tuesday':
      return 'Salı';
    case 'wednesday':
      return 'Çarşamba';
    case 'thursday':
      return 'Perşembe';
    case 'friday':
      return 'Cuma';
    case 'saturday':
      return 'Cumartesi';
    case 'sunday':
      return 'Pazar';
    default:
      return token;
  }
}

String bazaarDayShortTr(String token) {
  switch (token) {
    case 'monday':
      return 'Pzt';
    case 'tuesday':
      return 'Sal';
    case 'wednesday':
      return 'Çar';
    case 'thursday':
      return 'Per';
    case 'friday':
      return 'Cum';
    case 'saturday':
      return 'Cmt';
    case 'sunday':
      return 'Paz';
    default:
      return token;
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

  /// Mahalle pazarı için kurulduğu gün(ler). Sadece `type == bazaar` için
  /// anlamlı; diğer türlerde boş bırakılır. Token formatı `kBazaarDayTokens`
  /// içindeki lowercase İngilizce gün isimleri.
  final List<String> marketDays;

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
    this.marketDays = const <String>[],
  });

  factory StorePlace.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final m = doc.data() ?? <String, dynamic>{};
    final daysRaw = (m['marketDays'] as List?) ?? const [];
    final days = daysRaw
        .map((e) => e.toString().trim().toLowerCase())
        .where(kBazaarDayTokens.contains)
        .toSet()
        .toList(growable: false);
    return StorePlace(
      id: doc.id,
      chainId: (m['chainId'] as String?)?.trim().isNotEmpty == true
          ? (m['chainId'] as String)
          : null,
      chainName: (m['chainName'] as String?)?.trim().isNotEmpty == true
          ? (m['chainName'] as String)
          : null,
      type: storePlaceTypeFromString(m['type'] as String?),
      displayName: (m['displayName'] ?? m['name'] ?? '') as String,
      normalizedName: (m['normalizedName'] ?? '') as String,
      city: (m['city'] ?? m['cityName'] ?? '') as String,
      district: (m['district'] ?? m['districtName'] ?? '') as String,
      neighborhood: (m['neighborhood'] as String?)?.trim().isNotEmpty == true
          ? (m['neighborhood'] as String).trim()
          : null,
      lat: (m['lat'] as num?)?.toDouble(),
      lng: (m['lng'] as num?)?.toDouble(),
      status: (m['status'] ?? 'pending') as String,
      isActive: (m['isActive'] as bool?) ?? true,
      marketDays: days,
    );
  }

  bool get isBazaar => type == StorePlaceType.bazaar;

  /// Bugünün pazar günü mü?  `DateTime.now().weekday` üzerinden ölçer.
  bool isOpenToday({DateTime? now}) {
    if (marketDays.isEmpty) return false;
    final n = now ?? DateTime.now();
    return marketDays.contains(bazaarDayTokenForWeekday(n.weekday));
  }
}
