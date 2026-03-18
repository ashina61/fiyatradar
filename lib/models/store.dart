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
    bool? legacyIsOnline,
    DateTime? createdAt,
  }) : super(
          displayName: name,
          city: city,
          district: district,
          neighborhood: neighborhood,
          lat: lat,
          lng: lng,
          status: status,
          type: type == 'online' ? StoreType.online : StoreType.local,
          legacyIsOnline: legacyIsOnline,
          createdAt: createdAt ?? DateTime.now(),
        );

  final int? distanceMeters;
  final String logoUrl;
  final String? subtitle;

  String get typeLabel => isOnline ? 'online' : 'nearby';

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
      legacyIsOnline: model.legacyIsOnline,
      createdAt: model.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...toMap(),
      'type': typeLabel,
      'distance_meters': distanceMeters,
      'logoUrl': logoUrl,
      'subtitle': subtitle,
    };
  }
}
