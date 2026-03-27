import 'store_model.dart';

class Store extends StoreModel {
  Store({
    required super.id,
    required String name,
    required String type,
    required this.distanceMeters,
    required this.logoUrl,
    this.subtitle,
    super.brandId,
    String city = '',
    String district = '',
    String neighborhood = '',
    super.address,
    double lat = 0,
    double lng = 0,
    StoreStatus status = StoreStatus.active,
    String storeType = 'store',
    bool? legacyIsOnline,
    bool isTemporary = false,
    bool isRecurring = false,
    String? addressText,
    List<String> activeDays = const [],
    String? startHour,
    String? endHour,
    String? marketKind,
    List<String> searchKeywords = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : super(
          displayName: name,
          city: city,
          district: district,
          neighborhood: neighborhood,
          lat: lat,
          lng: lng,
          status: status,
          type: storeType == 'neighborhood_market'
              ? StoreType.neighborhoodMarket
              : (type == 'online' ? StoreType.onlineStore : StoreType.store),
          storeType: storeType,
          legacyIsOnline: legacyIsOnline,
          isTemporary: isTemporary,
          isRecurring: isRecurring,
          addressText: addressText,
          activeDays: activeDays,
          startHour: startHour,
          endHour: endHour,
          marketKind: marketKind,
          searchKeywords: searchKeywords,
          createdAt: createdAt ?? DateTime.now(),
          updatedAt: updatedAt,
        );

  final int? distanceMeters;
  final String logoUrl;
  final String? subtitle;

  String get typeLabel => isOnline ? 'online' : 'nearby';
  bool get isNeighborhoodMarket => storeType == 'neighborhood_market';

  factory Store.fromJson(Map<String, dynamic> json) {
    final model = StoreModel.fromMap(json);
    return Store.fromModel(
      model,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
      logoUrl: json['logoUrl'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
    );
  }

  factory Store.fromModel(
    StoreModel model, {
    int? distanceMeters,
    String? logoUrl,
    String? subtitle,
  }) {
    return Store(
      id: model.id,
      name: model.displayName,
      type: model.isOnline ? 'online' : 'nearby',
      distanceMeters: distanceMeters,
      logoUrl: logoUrl ?? (model.displayName.isNotEmpty ? model.displayName[0].toUpperCase() : '?'),
      subtitle: subtitle,
      brandId: model.brandId,
      city: model.city,
      district: model.district,
      neighborhood: model.neighborhood,
      address: model.address,
      lat: model.lat,
      lng: model.lng,
      status: model.status,
      storeType: model.storeType,
      legacyIsOnline: model.legacyIsOnline,
      isTemporary: model.isTemporary,
      isRecurring: model.isRecurring,
      addressText: model.addressText,
      activeDays: model.activeDays,
      startHour: model.startHour,
      endHour: model.endHour,
      marketKind: model.marketKind,
      searchKeywords: model.searchKeywords,
      createdAt: model.createdAt,
      updatedAt: model.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...toMap(),
      'type': typeLabel,
      'storeType': storeType,
      'distance_meters': distanceMeters,
      'logoUrl': logoUrl,
      'subtitle': subtitle,
    };
  }
}
